# =====================================================================================================================
# NTC NETWORK FIREWALL - CENTRALIZED NETWORK SECURITY INSPECTION
# =====================================================================================================================
# Advanced network protection for egress and east-west traffic inspection
#
# WHAT IS AWS NETWORK FIREWALL?
# ------------------------------
# Managed stateful network firewall and intrusion detection/prevention system (IDS/IPS)
# Deployed at the VPC level to inspect and filter network traffic based on rules you define
#
# WHY USE NETWORK FIREWALL?
# --------------------------
# Beyond Security Groups & NACLs:
#   ✓ Deep packet inspection (analyze content, not just headers)
#   ✓ Domain-based filtering (*.amazonaws.com, *.malware-site.com)
#   ✓ Application protocol detection (regardless of port)
#   ✓ Suricata IDS/IPS rules for threat detection
#   ✓ Centralized control for multiple VPCs via Transit Gateway
#
# DEPLOYMENT ARCHITECTURE: CENTRALIZED INSPECTION VPC
# ----------------------------------------------------
# Hub-and-Spoke Model with Transit Gateway:
#
#   ┌──────────────────────────────────────────────────────────┐
#   │                    INSPECTION VPC (Hub)                  │
#   │                                                          │
#   │               ┌─────────────────────────┐                │
#   │               │     Internet Gateway    │                │
#   │               │      + NAT Gateway      │                │
#   │               │        (Egress)         │                │
#   │               └────────────▲────────────┘                │
#   │                            │                             │
#   │   ┌──────────────┐  ┌──────┴───────┐  ┌──────────────┐   │
#   │   │  Firewall    │  │  Firewall    │  │  Firewall    │   │
#   │   │  Subnet 1a   │  │  Subnet 1b   │  │  Subnet 1c   │   │
#   │   │ (Network FW) │  │ (Network FW) │  │ (Network FW) │   │
#   │   └──────▲───────┘  └──────▲───────┘  └──────▲───────┘   │
#   │          │                 │                 │           │
#   │          └─────────────────┴─────────────────┘           │
#   │                            │                             │
#   └────────────────────────────┼─────────────────────────────┘
#                                │                             
#                    ┌───────────┴─────────────┐               
#                    │     Transit Gateway     │               
#                    │         (TGW)           │               
#                    └───────────▲─────────────┘               
#                                │
#         ┌──────────────────────┼──────────────────────┐
#         │                      │                      │
#   ┌─────┴─────┐          ┌─────┴─────┐          ┌─────┴─────┐
#   │  Workload │          │  Workload │          │  Workload │
#   │  VPC 1    │          │  VPC 2    │          │  VPC 3    │
#   │  (Spoke)  │          │  (Spoke)  │          │  (Spoke)  │
#   └───────────┘          └───────────┘          └───────────┘
#
# Traffic Flow:
#   1. Egress: Workload VPC → TGW → Inspection VPC → Network Firewall → Internet
#   2. East-West: VPC 1 → TGW → Inspection VPC → Network Firewall → TGW → VPC 2
#   3. All traffic passes through firewall for inspection and filtering
#
# Benefits:
#   ✓ Single point of control for all traffic inspection
#   ✓ Consistent security policies across entire organization
#   ✓ Simplified management (one firewall vs. per-VPC solutions)
#   ✓ Cost optimization (shared firewall infrastructure)
#   ✓ Scalability (automatically scales with traffic)
#
# RULE PROCESSING ORDER
# ---------------------
# 1. STATELESS (Wire Speed): Header-based filtering → DROP, PASS, or FORWARD to stateful
# 2. STATEFUL (Deep Inspection): Domain lists, 5-tuple rules, Suricata IPS signatures
# 3. DEFAULT ACTIONS: Applied when no rules match
#
# Rule Order Modes:
#   • STRICT_ORDER: Evaluated by priority (1 = highest)
#   • DEFAULT_ACTION_ORDER: All PASS rules first, then DROP rules
#
# RULE GROUP TYPES EXPLAINED
# ---------------------------
# STATELESS RULE GROUPS:
#   Purpose: Fast packet filtering at wire speed
#   Use Cases:
#     ✓ Block SSH (port 22) from internet
#     ✓ Block RDP (port 3389) from untrusted networks
#     ✓ Drop packets from known malicious IPs
#     ✓ Rate limiting (using custom actions)
#   
#   Limitations:
#     ✗ No application awareness
#     ✗ No connection tracking
#     ✗ Cannot inspect packet payload
#
# STATEFUL RULE GROUPS - Domain List:
#   Purpose: Allow/deny traffic by domain name
#   Use Cases:
#     ✓ Egress Filtering: Only allow *.amazonaws.com, *.github.com
#     ✓ Block malicious domains (*.malware-site.com)
#     ✓ Compliance: Restrict access to approved SaaS services
#   
#   Types:
#     - ALLOWLIST: Only specified domains are allowed (deny all others)
#     - DENYLIST: Only specified domains are blocked (allow all others)
#   
#   Protocols: HTTP_HOST, TLS_SNI (inspects Host header and SNI)
#
# STATEFUL RULE GROUPS - 5-Tuple:
#   Purpose: Traditional firewall rules (IP, port, protocol)
#   Use Cases:
#     ✓ Allow HTTPS (443) to internet
#     ✓ Allow database access on specific ports
#     ✓ Block traffic between environments (prod ↔ dev)
#   
#   Components:
#     - Protocol: TCP, UDP, ICMP
#     - Source IP/CIDR and Port
#     - Destination IP/CIDR and Port
#     - Direction: FORWARD (outbound), ANY (bidirectional)
#     - Action: PASS, DROP, ALERT, REJECT
#
# STATEFUL RULE GROUPS - Suricata IPS:
#   Purpose: Advanced threat detection with signature matching
#   Use Cases:
#     ✓ Detect SQL injection attempts
#     ✓ Identify command & control traffic
#     ✓ Block exploitation of known vulnerabilities
#     ✓ Custom threat detection rules
#   
#   Example Rule:
#     alert tcp any any -> any 4444 (msg:"Metasploit default payload port"; sid:1000001;)
#   
#   Suricata Rule Variables:
#     - $HOME_NET: Define trusted network ranges
#     - $EXTERNAL_NET: Define external networks
#     - Custom variables for IP sets and port sets
#
# AWS MANAGED RULE GROUPS - AUTOMATIC THREAT PROTECTION
# ------------------------------------------------------
# Pre-configured, AWS-maintained rule sets updated automatically
#
# Available Rule Groups (must match rule order suffix):
#   STRICT_ORDER (evaluated in priority order):
#     • AbusedLegitMalwareDomainsStrictOrder
#     • ThreatSignaturesBotnetStrictOrder
#     • ThreatSignaturesEmergingEventsStrictOrder
#     • ThreatSignaturesMalwareStrictOrder
#     • ThreatSignaturesWebAttacksStrictOrder
#
#   DEFAULT_ACTION_ORDER (all PASS rules first, then DROP):
#     • AbusedLegitMalwareDomainsActionOrder
#     • ThreatSignaturesBotnetActionOrder
#     • ThreatSignaturesEmergingEventsActionOrder
#     • (etc.)
#
# Best Practices:
#   ✓ Start with Malware Domains and Botnet (low false positives)
#   ✓ Test Web Attacks separately (may block legitimate traffic)
#   ✓ Use override actions to tune rules without disabling entirely
#   ✓ Review findings regularly to optimize rule set
#
# LOGGING CONFIGURATION - VISIBILITY & COMPLIANCE
# ------------------------------------------------
# Three Log Types (can be sent to different destinations):
#
# 1. ALERT Logs:
#    • What: Rules that trigger ALERT or DROP actions
#    • When: Threat detected, policy violation, blocked traffic
#    • Use: Security monitoring, threat hunting, compliance
#    • Volume: Low-Medium (only logged when rules trigger)
#
# 2. FLOW Logs:
#    • What: All TCP connections (stateful inspection)
#    • When: Connection establishment, data transfer, termination
#    • Use: Network analysis, troubleshooting, capacity planning
#    • Volume: High (every connection logged)
#    • ⚠️  Can be expensive for high-traffic environments
#
# 3. TLS Logs:
#    • What: TLS/SSL handshake metadata (SNI, certificates)
#    • When: TLS connections established
#    • Use: Detect malicious certificates, analyze TLS usage
#    • Volume: Medium (every TLS connection)
#
# Log Destinations:
#   • CloudWatch Logs: Real-time monitoring, alerting, analysis
#   • S3: Long-term retention, compliance archives, cost-effective
#   • Kinesis Data Firehose: Stream to SIEM or analytics platforms
#
# COST CONSIDERATIONS
# -------------------
# Frankfurt Example: $0.395/hr per AZ + $0.065/GB processed
# 3 AZs + 10TB/month ≈ $1,515/month
#
# Not Cost-Effective For:
#   • Simple IP-based allow/deny (use Security Groups)
#   • Basic internet access (NAT Gateway sufficient)
#   • Very low traffic volumes
#
# BEST PRACTICES
# --------------
# ✓ Start with deny-by-default, explicit allows
# ✓ Enable ALERT logs (critical for security)
# ✓ Test AWS Managed Rule Groups for false positives
# ✓ Plan capacity generously (cannot change later)
# ✓ Use domain lists for egress filtering
# ✓ Document all custom rules
# ✓ Review and tune quarterly
# =====================================================================================================================

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC NETWORK FIREWALL
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_network_firewall" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-network-firewall?ref=2.0.0"

  region = "eu-central-1"
  # -------------------------------------------------------------------------------------------------------------------
  # Firewall Identity and Deployment
  # -------------------------------------------------------------------------------------------------------------------
  firewall_name = "network-firewall"
  description   = "Network Firewall for central inspection of egress and east-west traffic"
  vpc_id        = module.ntc_vpc_inspection.vpc_id
  subnet_ids    = module.ntc_vpc_inspection.active_subnet_ids["firewall"]

  # -------------------------------------------------------------------------------------------------------------------
  # Protection Settings - Prevent Accidental Changes
  # -------------------------------------------------------------------------------------------------------------------
  # Recommendation for Production:
  #   delete_protection        = true   # Prevent accidental firewall deletion
  #   subnet_change_protection = true   # Prevent traffic bypass via subnet changes
  #   policy_change_protection = false  # Allow policy updates (managed by security team)
  # -------------------------------------------------------------------------------------------------------------------
  delete_protection        = false
  subnet_change_protection = false
  policy_change_protection = false

  # -------------------------------------------------------------------------------------------------------------------
  # Firewall Policy Configuration
  # -------------------------------------------------------------------------------------------------------------------
  # Rule Processing Flow:
  #   1. Stateless rules evaluate packets first (fast path)
  #   2. If forwarded, stateful rules inspect deeply (connection tracking)
  #   3. Default actions apply when no rules match
  # -------------------------------------------------------------------------------------------------------------------
  firewall_policy = {
    # Stateless Default Actions (when no stateless rules match):
    #   - aws:forward_to_sfe: Forward to stateful engine for deep inspection (recommended)
    #   - aws:pass: Allow traffic to pass through
    #   - aws:drop: Drop traffic silently
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    # Stateful Default Actions (when no stateful rules match):
    #   - aws:drop_strict: Drop all traffic that doesn't match any PASS rule
    #   - aws:drop_established: Drop only established connections (allow new)
    #   - aws:alert_strict: Alert but allow (useful for monitoring mode)
    stateful_default_actions = ["aws:drop_strict"]

    # Stateful Engine Rule Order:
    #   - STRICT_ORDER: Rules evaluated in priority order (traditional firewall)
    #   - DEFAULT_ACTION_ORDER: All PASS rules first, then DROP rules
    stateful_engine_options_rule_order = "STRICT_ORDER"
  }

  # -------------------------------------------------------------------------------------------------------------------
  # RULE GROUP CAPACITY UNITS - CRITICAL PLANNING CONSIDERATION
  # -------------------------------------------------------------------------------------------------------------------
  # Every rule group has a 'capacity' setting that determines processing resources.
  #
  # WHAT ARE CAPACITY UNITS?
  #   • Represent processing complexity required for rules
  #   • Different rule types consume different amounts:
  #     - Stateless rules: ~3-5 units per rule
  #     - 5-tuple stateful: ~1-3 units per rule
  #     - Domain list: ~1 unit per domain
  #     - Suricata IPS: ~10-100+ units (varies by complexity)
  #
  # ⚠️  CRITICAL: Capacity is IMMUTABLE after creation!
  #   • Cannot be changed once rule group is created
  #   • Must delete and recreate to change capacity
  #   • Always provision 20-30% extra headroom for growth
  #
  # FIREWALL CAPACITY LIMITS:
  #   • Total capacity limit: 30,000 units per firewall
  #   • Includes ALL rule groups (stateless + stateful + AWS managed)
  #   • AWS managed groups have fixed capacity (e.g., AttackInfrastructure = 15,000)
  #   • Plan carefully to stay within limit!
  #
  # CAPACITY PLANNING EXAMPLE:
  #   Stateless groups:      500 units
  #   Custom stateful:     5,000 units
  #   AWS managed groups: 20,000 units
  #   Reserved buffer:     3,000 units
  #   ─────────────────────────────────
  #   Total:              28,500 / 30,000 (95% utilized)
  #
  # RECOMMENDATIONS:
  #   ✓ Stateless groups: Start with 100-500 units
  #   ✓ 5-tuple groups: Start with 100-500 units
  #   ✓ Domain lists: Start with 100-200 units (1 unit per domain)
  #   ✓ Suricata groups: Start with 500-2,000 units (complexity varies)
  #   ✓ Leave 3,000-5,000 units buffer for future additions
  # -------------------------------------------------------------------------------------------------------------------

  # -------------------------------------------------------------------------------------------------------------------
  # Stateless Rule Groups - Fast Packet Filtering at Wire Speed
  # -------------------------------------------------------------------------------------------------------------------
  # Purpose: Block obvious threats before deep inspection (performance optimization)
  # 
  # Common Use Cases:
  #   • Block SSH/RDP from internet (reduce attack surface)
  #   • Drop packets from known malicious IPs
  #   • Rate limiting using custom actions
  #   • Block uncommon protocols
  #
  # Best Practices:
  #   ✓ Keep rules simple (IP, port, protocol only)
  #   ✓ Use low capacity values (rules are evaluated quickly)
  #   ✓ Higher priority = evaluated first (1 is highest)
  #   ✓ Always forward to stateful engine for deep inspection
  # -------------------------------------------------------------------------------------------------------------------
  stateless_rule_groups = [
    # =================================================================================================================
    # Example: Block Common Attack Ports
    # =================================================================================================================
    # Reduces attack surface by dropping SSH and RDP traffic at wire speed
    # These are common targets for brute force and exploitation attempts
    # =================================================================================================================
    {
      name        = "block-common-attacks"
      description = "Block common network attacks at wire speed"
      capacity    = 100 # Capacity units consumed (max 30,000 per rule group)
      priority    = 1   # Evaluation priority (lower number = higher priority)

      rules = [
        {
          priority          = 1
          actions           = ["aws:drop"]                     # Drop packet silently
          protocols         = ["TCP"]                          # TCP protocol
          source_cidrs      = ["0.0.0.0/0"]                    # From any source
          source_port       = null                             # Any source port
          destination_cidrs = ["0.0.0.0/0"]                    # To any destination
          destination_port  = { from_port = 22, to_port = 22 } # SSH (port 22)
        },
        {
          priority          = 2
          actions           = ["aws:drop"]
          protocols         = ["TCP"]
          source_cidrs      = ["0.0.0.0/0"]
          source_port       = null
          destination_cidrs = ["0.0.0.0/0"]
          destination_port  = { from_port = 3389, to_port = 3389 } # RDP (port 3389)
        }
      ]
    }
    # Additional stateless rule group examples:
    #
    # Rate Limiting:
    # {
    #   name = "rate-limit-connections"
    #   description = "Rate limit new connections per source IP"
    #   capacity = 200
    #   priority = 2
    #   rules = [ ... with custom rate limit actions ... ]
    # }
    #
    # Block Specific IP Ranges:
    # {
    #   name = "block-malicious-ips"
    #   description = "Drop traffic from known malicious IP ranges"
    #   capacity = 50
    #   priority = 3
    #   rules = [ ... with specific source_cidrs ... ]
    # }
  ]

  # -------------------------------------------------------------------------------------------------------------------
  # Stateful Rule Groups - Deep Packet Inspection & Application Awareness
  # -------------------------------------------------------------------------------------------------------------------
  # Purpose: Control traffic based on domain names, application protocols, and connection state
  #
  # Three Types Available:
  #   1. domain_list: Allow/deny by domain name (egress filtering)
  #   2. 5tuple: Traditional firewall rules (IP, port, protocol, direction)
  #   3. suricata: Advanced IDS/IPS with custom Suricata rules
  #
  # Best Practices:
  #   ✓ Use domain lists for egress filtering (easy to maintain)
  #   ✓ Use 5-tuple for precise network segmentation
  #   ✓ Use Suricata for advanced threat detection
  #   ✓ Organize by purpose (egress, east-west, security)
  #   ✓ Document each rule group's purpose
  # -------------------------------------------------------------------------------------------------------------------
  stateful_rule_groups = [
    # =================================================================================================================
    # Domain List - ALLOWLIST (Egress Filtering)
    # =================================================================================================================
    # WHAT: Whitelist of allowed domains for internet egress
    # WHY: Prevent data exfiltration and restrict access to approved services only
    #
    # How it works:
    #   • Only domains in this list are allowed
    #   • All other domains are implicitly blocked
    #   • Inspects HTTP Host header and TLS SNI
    #
    # Use Cases:
    #   ✓ Restrict egress to AWS services and approved vendors only
    #   ✓ Compliance requirement to control data flows
    #   ✓ Prevent malware callback to C2 servers
    #   ✓ Block unauthorized SaaS usage
    #
    # Maintenance:
    #   • Add new domains as services are approved
    #   • Use wildcard (*.example.com) for all subdomains
    #   • Monitor ALERT logs for blocked legitimate traffic
    #   • Review quarterly to remove unused domains
    # =================================================================================================================
    {
      name            = "allowed-domains"
      description     = "Whitelist of allowed domains for egress"
      capacity        = 100
      priority        = 10 # Lower priority than security blocks
      rule_group_type = "domain_list"

      domain_list_config = {
        type = "ALLOWLIST" # Only these domains are allowed
        targets = [
          ".amazonaws.com", # AWS services
          ".amazon.com",    # Amazon resources
          ".github.com",    # Code repositories
          ".docker.io",     # Container images
          ".ubuntu.com"     # Package updates
          # Add your approved domains here:
          # ".your-company.com",
          # ".approved-vendor.com",
          # ".monitoring-tool.io"
        ]
        protocol_types = ["HTTP_HOST", "TLS_SNI"] # Inspect both HTTP and HTTPS
      }
    },

    # =================================================================================================================
    # Domain List - DENYLIST (Block Known Malicious Domains)
    # =================================================================================================================
    # WHAT: Blocklist of malicious or restricted domains
    # WHY: Prevent access to known threats, phishing sites, or policy-restricted domains
    #
    # How it works:
    #   • Domains in this list are blocked
    #   • All other domains are allowed (if not using ALLOWLIST above)
    #   • Can be used in combination with ALLOWLIST
    #
    # Use Cases:
    #   ✓ Block known malware distribution sites
    #   ✓ Block phishing domains
    #   ✓ Block competitors or restricted content
    #   ✓ Block specific social media or streaming services
    #
    # Maintenance:
    #   • Update regularly with threat intelligence feeds
    #   • Remove false positives if legitimate domains blocked
    #   • Consider AWS Managed Rule Groups for automatic updates
    # =================================================================================================================
    {
      name            = "blocked-domains"
      description     = "Blocklist of malicious or restricted domains"
      capacity        = 50
      priority        = 5 # Higher priority than allowlist (block first)
      rule_group_type = "domain_list"

      domain_list_config = {
        type = "DENYLIST" # Block these domains
        targets = [
          ".example-malicious.com",
          ".blocked-site.org"
          # Add known malicious domains:
          # ".phishing-site.xyz",
          # ".malware-host.tk",
          # ".c2-server.cc"
        ]
        protocol_types = ["HTTP_HOST", "TLS_SNI"]
      }
    },

    # =================================================================================================================
    # 5-Tuple Rules - Traditional Firewall (IP, Port, Protocol)
    # =================================================================================================================
    # WHAT: Traditional firewall rules based on IP addresses, ports, and protocols
    # WHY: Precise control over network flows between specific sources and destinations
    #
    # Components:
    #   • action: PASS (allow), DROP (block), ALERT (log but allow), REJECT (send reset)
    #   • protocol: TCP, UDP, ICMP, or IP protocol number
    #   • source_cidr: Source IP address or CIDR block
    #   • source_port: Source port (usually "ANY" for clients)
    #   • direction: FORWARD (outbound) or ANY (bidirectional)
    #   • destination_cidr: Destination IP or CIDR
    #   • destination_port: Specific port number or range
    #   • sid: Signature ID (must be unique per rule)
    #
    # Use Cases:
    #   ✓ Allow specific protocols to internet
    #   ✓ Block traffic between VPCs (network segmentation)
    #   ✓ Allow database access on specific ports
    #   ✓ Implement zero-trust network segmentation
    # =================================================================================================================
    {
      name            = "allow-https-egress"
      description     = "Allow HTTPS egress to internet"
      capacity        = 50
      priority        = 20
      rule_group_type = "5tuple"

      five_tuple_config = {
        rules = [
          {
            action           = "PASS" # Allow traffic
            protocol         = "TCP"
            source_cidr      = "172.16.0.0/12" # From any VPC CIDR
            source_port      = "ANY"           # Any client port
            direction        = "FORWARD"       # Outbound only
            destination_cidr = "0.0.0.0/0"     # To anywhere on internet
            destination_port = "443"           # HTTPS
            sid              = 1               # Unique signature ID
            description      = "Allow HTTPS egress"
          },
          {
            action           = "DROP"
            protocol         = "TCP"
            source_cidr      = "172.16.0.0/12"
            source_port      = "ANY"
            direction        = "FORWARD"
            destination_cidr = "0.0.0.0/0"
            destination_port = "80" # HTTP
            sid              = 2
            description      = "Drop HTTP egress"
          }
          # Additional 5-tuple rule examples:
          #
          # Block inter-VPC traffic (network segmentation):
          # {
          #   action = "DROP"
          #   protocol = "TCP"
          #   source_cidr = "10.1.0.0/16"        # Production VPC
          #   source_port = "ANY"
          #   direction = "FORWARD"
          #   destination_cidr = "10.2.0.0/16"   # Development VPC
          #   destination_port = "ANY"
          #   sid = 100
          #   description = "Block prod to dev traffic"
          # }
          #
          # Allow database access:
          # {
          #   action = "PASS"
          #   protocol = "TCP"
          #   source_cidr = "10.100.1.0/24"      # App subnet
          #   source_port = "ANY"
          #   direction = "FORWARD"
          #   destination_cidr = "10.100.2.0/24" # DB subnet
          #   destination_port = "5432"          # PostgreSQL
          #   sid = 200
          #   description = "Allow app to database"
          # }
        ]
      }
    },

    # =================================================================================================================
    # Suricata IPS Rules - Advanced Threat Detection
    # =================================================================================================================
    # WHAT: Custom Suricata rules for intrusion detection and prevention
    # WHY: Detect and block sophisticated attacks that bypass simple IP/port filtering
    #
    # Suricata Rule Format:
    #   action protocol source_ip source_port -> dest_ip dest_port (options)
    #
    # Actions:
    #   • alert: Log but allow (detection mode)
    #   • drop: Block traffic (prevention mode)
    #   • reject: Block and send TCP reset
    #   • pass: Explicitly allow
    #
    # Common Use Cases:
    #   ✓ Detect SQL injection attempts
    #   ✓ Block command & control traffic
    #   ✓ Identify malware beaconing
    #   ✓ Detect data exfiltration
    #   ✓ Block exploitation attempts
    #
    # Rule Variables:
    #   • $HOME_NET: Your trusted network(s)
    #   • $EXTERNAL_NET: Everything else
    #   • Custom variables for IP sets and port sets
    #
    # Best Practices:
    #   ✓ Start with alert mode, switch to drop after tuning
    #   ✓ Use rule variables for maintainability
    #   ✓ Test rules in non-production first
    #   ✓ Monitor false positives
    #   ✓ Document rule purpose and source
    #
    # Resources:
    #   • Suricata Documentation: https://suricata.readthedocs.io/
    #   • Emerging Threats Rules: https://rules.emergingthreats.net/
    #   • OISF Rule Format: https://suricata.io/
    # =================================================================================================================
    {
      name            = "emerging-threats"
      description     = "Custom Suricata rules for threat detection"
      capacity        = 200
      priority        = 30
      rule_group_type = "suricata"

      suricata_config = {
        rules_string = <<-EOT
          # === CRITICAL: Active Blocking Rules ===
          
          # Block RDP on non-standard ports (evasion attempt)
          drop rdp any any -> any !3389 (msg:"RDP on non-standard port blocked"; flow:to_server; sid:1000006; rev:1;)
          
          # Block SSH on non-standard ports (evasion attempt)
          drop ssh any any -> any !22 (msg:"SSH on non-standard port blocked"; flow:to_server; sid:1000005; rev:1;)
          
          # Block known malicious ports
          drop tcp any any -> any 1234 (msg:"Backdoor access attempt blocked"; flow:to_server; sid:1000007; rev:1;)
          drop tcp any any -> any 4444 (msg:"Metasploit payload port blocked"; flow:to_server; sid:1000008; rev:1;)
          
          # === HIGH: Detection & Alerting ===
          
          # Detect SQL injection attempts (more specific pattern)
          alert http any any -> any any (msg:"SQL injection attempt - UNION SELECT"; content:"UNION"; nocase; content:"SELECT"; nocase; distance:0; http_uri; sid:1000004; rev:2;)
          
          # Detect SQL injection - OR 1=1 pattern
          alert http any any -> any any (msg:"SQL injection attempt - OR 1=1"; pcre:"/(\%27)|(\')|(\-\-)|(\%23)|(#)/i"; content:"OR"; nocase; content:"1=1"; nocase; distance:0; http_uri; sid:1000009; rev:1;)
          
          # Detect command injection attempts (shell metacharacters in URI)
          alert http any any -> any any (msg:"Command injection - semicolon"; content:"|3b|"; http_uri; sid:1000010; rev:1;)
          alert http any any -> any any (msg:"Command injection - pipe"; content:"|7c|"; http_uri; sid:1000013; rev:1;)
          alert http any any -> any any (msg:"Command injection - ampersand"; content:"|26|"; http_uri; sid:1000014; rev:1;)
          alert http any any -> any any (msg:"Command injection - backtick"; content:"|60|"; http_uri; sid:1000015; rev:1;)
          
          # Detect suspicious automation (non-browser user agents to web apps)
          alert http any any -> any any (msg:"Automated scanner detected"; content:"sqlmap"; http_user_agent; nocase; sid:1000011; rev:1;)
          alert http any any -> any any (msg:"Automated scanner detected"; content:"nikto"; http_user_agent; nocase; sid:1000012; rev:1;)
          
          # === MEDIUM: Anomaly Detection ===
          
          # Detect SSH brute force attempts
          alert ssh $EXTERNAL_NET any -> $HOME_NET 22 (msg:"Potential SSH brute force"; flow:to_server; threshold:type threshold, track by_src, count 5, seconds 60; sid:1000021; rev:1;)
          
          # Detect RDP brute force attempts  
          alert rdp $EXTERNAL_NET any -> $HOME_NET 3389 (msg:"Potential RDP brute force"; flow:to_server; threshold:type threshold, track by_src, count 5, seconds 60; sid:1000022; rev:1;)

          # === COMPLIANCE: Data Protection ===

          # Detect unencrypted database traffic (common database ports)
          alert tcp $HOME_NET any -> any [3306,5432,1433] (msg:"Unencrypted database traffic detected"; flow:to_server; sid:1000016; rev:1;)

          # Detect cleartext credentials (basic auth)
          alert http any any -> any any (msg:"HTTP Basic Auth detected"; content:"Authorization: Basic"; http_header; sid:1000017; rev:1;)

          # Detect potential PII exfiltration patterns (email addresses in GET requests)
          alert http $HOME_NET any -> $EXTERNAL_NET any (msg:"Potential PII in URL"; content:"@"; http_uri; pcre:"/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/"; sid:1000018; rev:1;)
        EOT

        # Rule variables for maintainability
        rule_variables = {
          HOME_NET     = ["172.16.0.0/12"] # Your VPC CIDRs
          EXTERNAL_NET = ["!$HOME_NET"]    # Everything else
        }
      }
    }
  ]

  # -------------------------------------------------------------------------------------------------------------------
  # AWS Managed Rule Groups - Automatic Threat Protection
  # -------------------------------------------------------------------------------------------------------------------
  # Purpose: Pre-configured, AWS-maintained rule sets with automatic threat intelligence updates
  #
  # Benefits:
  #   ✓ No manual rule creation or maintenance required
  #   ✓ Automatically updated with latest threats
  #   ✓ Low false positive rates (tuned by AWS)
  #   ✓ Curated by AWS security team
  #
  # Available Rule Groups (STRICT_ORDER suffix):
  #   • AbusedLegitMalwareDomainsStrictOrder: Compromised legitimate domains
  #   • ThreatSignaturesBotnetStrictOrder: Known botnet C2 servers
  #   • ThreatSignaturesEmergingEventsStrictOrder: Recent threats
  #   • ThreatSignaturesMalwareStrictOrder: Malware distribution
  #   • ThreatSignaturesWebAttacksStrictOrder: Web exploitation attempts
  #
  # ⚠️  IMPORTANT: Rule group suffix must match firewall policy rule order
  #   • STRICT_ORDER → use "StrictOrder" suffix
  #   • DEFAULT_ACTION_ORDER → use "ActionOrder" suffix
  #
  # Recommendations:
  #   ✓ Start with: Malware Domains + Botnet (minimal false positives)
  #   ✓ Add carefully: Web Attacks (may block legitimate traffic)
  #   ✓ Monitor ALERT logs for false positives
  #   ✓ Use override actions to tune without disabling
  #
  # Priority Assignment:
  #   • Higher numbers = lower priority (evaluated later)
  #   • Place after your custom rules (100+)
  #   • Keep 10-20 priority gap between groups for future insertions
  # -------------------------------------------------------------------------------------------------------------------
  aws_managed_rule_groups = [
    {
      name     = "ThreatSignaturesBotnetStrictOrder" # Block known botnet command & control servers
      priority = 100                                 # Evaluated after custom rules (priority 1-30)
    },
    {
      name     = "AbusedLegitMalwareDomainsStrictOrder" # Block compromised legitimate domains
      priority = 120                                    # 20 priority gap for future insertion
    }
    # Additional AWS Managed Rule Groups (add as needed):
    #
    # {
    #   name = "ThreatSignaturesMalwareStrictOrder"       # Malware distribution sites
    #   priority = 140
    # },
    # {
    #   name = "ThreatSignaturesWebAttacksStrictOrder"    # ⚠️ May block legitimate traffic
    #   priority = 160
    # },
    # {
    #   name = "ThreatSignaturesEmergingEventsStrictOrder" # Latest emerging threats
    #   priority = 180
    # }
  ]

  # ===================================================================================================================
  # LOGGING CONFIGURATION - Traffic Visibility & Audit
  # ===================================================================================================================
  # Purpose: Capture firewall decisions for security monitoring, compliance, and troubleshooting
  #
  # Three Log Types:
  #
  #   1. ALERT Logs (Security Events)
  #      • When: Rule matches traffic (block or allow)
  #      • Contains: Rule ID, action taken, src/dst IP, ports, protocol
  #      • Use cases:
  #        ✓ Security incident investigation
  #        ✓ Compliance auditing (what was blocked/allowed)
  #        ✓ Rule effectiveness analysis
  #        ✓ Threat hunting
  #      • Volume: LOW (only rule matches)
  #      • Recommendation: ALWAYS enable, send to CloudWatch for long-term retention
  #
  #   2. FLOW Logs (Session Metadata)
  #      • When: Every network flow (allowed traffic only)
  #      • Contains: Bytes, packets, duration, src/dst IP, ports, protocol
  #      • Use cases:
  #        ✓ Network troubleshooting (connection issues)
  #        ✓ Bandwidth analysis
  #        ✓ Application dependency mapping
  #        ✓ Cost allocation
  #      • Volume: MEDIUM (one log per flow, aggregated)
  #      • Recommendation: Enable for production, disable for cost savings
  #
  #   3. TLS Logs (Encrypted Traffic Metadata)
  #      • When: TLS/SSL connections established
  #      • Contains: SNI hostname, certificates, cipher suites, TLS version
  #      • Use cases:
  #        ✓ Identify HTTPS destinations without decryption
  #        ✓ Certificate validation issues
  #        ✓ TLS protocol compliance (block old versions)
  #        ✓ Shadow IT discovery
  #      • Volume: MEDIUM-HIGH (every HTTPS connection)
  #      • Recommendation: Enable for enhanced visibility
  #
  # Destination Options:
  #
  #   CloudWatch Logs (log_group_name):
  #     • Best for: Real-time monitoring, alerting, long-term retention
  #     • Cost: Storage + ingestion (~$0.50/GB in us-east-1)
  #     • Features: CloudWatch Insights queries, metric filters, alarms
  #     • Use when: You need real-time alerting or query capabilities
  #
  #   S3 Bucket (bucket_name):
  #     • Best for: Cost-effective long-term storage, compliance archival
  #     • Cost: Storage only (~$0.023/GB Standard, $0.004/GB IA)
  #     • Features: Athena queries, Glacier archival, lifecycle policies
  #     • Use when: You need cheap bulk storage or compliance retention
  #
  #   Kinesis Data Firehose (delivery_stream_name):
  #     • Best for: Streaming to SIEM, data lake, or custom processor
  #     • Cost: Data ingested (~$0.029/GB) + destination costs
  #     • Features: Transform data, send to Splunk/Datadog/Elasticsearch
  #     • Use when: You have existing log aggregation infrastructure
  #
  # Security Best Practices:
  #   ✓ Enable KMS encryption for CloudWatch Logs (compliance requirement)
  #   ✓ Set appropriate retention (90+ days for security, 7 years for compliance)
  #   ✓ Use separate log groups per firewall for isolation
  #   ✓ Grant least privilege IAM permissions
  #   ✓ Monitor for unexpected log volume spikes (DDoS indicator)
  #
  # Cost Optimization:
  #   • Start with ALERT logs only (minimal cost)
  #   • Add FLOW logs for production workloads
  #   • Add TLS logs only if domain visibility is required
  #   • Use S3 for long-term retention (cheaper than CloudWatch)
  #   • Set CloudWatch retention to 30-90 days, archive to S3 after
  #   • Use S3 Intelligent-Tiering or Lifecycle policies for old logs
  #
  # Example Log Queries (CloudWatch Insights):
  #   • Top blocked destinations:
  #     fields event.dest_ip, event.dest_port | filter event.action = "blocked" | stats count() by event.dest_ip | sort count desc
  #
  #   • Top bandwidth consumers (FLOW logs):
  #     fields event.src_ip, event.bytes | stats sum(event.bytes) as total_bytes by event.src_ip | sort total_bytes desc
  #
  #   • Identify blocked domains (ALERT logs + domain list rules):
  #     fields event.timestamp, event.domain, event.src_ip | filter event.action = "blocked" and event.rule_group like "domain"
  # ===================================================================================================================

  # -------------------------------------------------------------------------------------------------------------------
  # Logging Configuration - Actual Implementation
  # -------------------------------------------------------------------------------------------------------------------
  # Configuration below demonstrates all three log types with CloudWatch Logs as destination
  # Adjust based on your needs (see detailed documentation above)
  # -------------------------------------------------------------------------------------------------------------------
  logging_configuration = {
    # Enables the detailed firewall monitoring dashboard in the AWS Console (additional charges apply).
    # Provides visual insights into firewall activity, traffic patterns, and rule matches.
    # Default: false
    enable_monitoring_dashboard = true

    # ALERT logs - Security events (blocks and allows from rule matches)
    # Enable: ALWAYS (critical for security monitoring)
    # Volume: LOW
    # Retention: 90+ days for security analysis, 1+ year for compliance
    alert = {
      log_destination_type = "CloudWatchLogs"              # CloudWatch | S3 | KinesisDataFirehose
      create_log_group     = true                          # Module creates log group automatically
      log_group_name       = "/aws/network-firewall/alert" # Prefix recommended: /aws/network-firewall/
      retention_days       = 14                            # 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    }

    # FLOW logs - Network flow metadata (allowed traffic only)
    # Enable: Production workloads (helpful for troubleshooting)
    # Volume: MEDIUM
    # Retention: 7-30 days (cost vs. troubleshooting value)
    flow = {
      log_destination_type = "CloudWatchLogs"
      create_log_group     = true
      log_group_name       = "/aws/network-firewall/flow"
      retention_days       = 14
    }

    # TLS logs - HTTPS connection metadata (SNI, certificates)
    # Enable: When domain visibility is required (optional)
    # Volume: MEDIUM-HIGH
    # Retention: 7-14 days (mostly for troubleshooting)
    tls = {
      log_destination_type = "CloudWatchLogs"
      create_log_group     = true
      log_group_name       = "/aws/network-firewall/tls"
      retention_days       = 14
    }

    # -------------------------------------------------------------------------------------------------------------------
    # Alternative Destination Examples:
    # -------------------------------------------------------------------------------------------------------------------
    #
    # S3 Bucket (cost-effective long-term storage):
    # alert = {
    #   log_destination_type = "S3"
    #   bucket_name          = "my-network-firewall-logs"
    #   prefix               = "alert/"                   # Optional: organize by log type
    # }
    #
    # Kinesis Data Firehose (stream to SIEM):
    # alert = {
    #   log_destination_type = "KinesisDataFirehose"
    #   delivery_stream_name = "network-firewall-to-splunk"
    # }
    #
    # Disable specific log type (comment out or remove):
    # # flow = { ... }  # Commenting out disables FLOW logs
    # -------------------------------------------------------------------------------------------------------------------
  }
}
