#/bin/bash

_load_module bash::strings

function _cloudconfig_content() {
  content='|' _vars_to_yaml content
  _indent_spaces 4
}

function _cloudconfig_gen_format_spec() {
  #local root_='coreos ssh_authorized_keys hostname users write_files manage_etc_hosts'
  local root_coreos_fleet_='agent_ttl: An Agent will be considered dead if it exceeds this amount of time to communicate with the Registry
    engine_reconcile_interval: Interval in seconds at which the engine should reconcile the cluster schedule in etcd
    etcd_cafile: Path to CA file used for TLS communication with etcd
    etcd_certfile: Provide TLS configuration when SSL certificate authentication is enabled in etcd endpoints
    etcd_keyfile: Path to private key file used for TLS communication with etcd
    etcd_key_prefix: etcd prefix path to be used for fleet keys
    etcd_request_timeout: Amount of time in seconds to allow a single etcd request before considering it failed
    etcd_servers: Comma separated list of etcd endpoints
    etcd_username: Username for Basic Authentication to etcd endpoints
    etcd_password: Password for Basic Authentication to etcd endpoints
    metadata: Comma separated key/value pairs that are published with the local to the fleet registry
    public_ip: IP accessible by other nodes for inter-host communication
    verbosity: Enable debug logging by setting this to an integer value greater than zero
'
  local root_coreos_flannel_='etcd_endpoints: Comma separated list of etcd endpoints
    etcd_cafile: Path to CA file used for TLS communication with etcd
    etcd_certfile: Path to certificate file used for TLS communication with etcd
    etcd_keyfile: Path to private key file used for TLS communication with etcd
    etcd_prefix: etcd prefix path to be used for flannel keys
    etcd_username: Username for Basic Authentication to etcd endpoints
    etcd_password: Password for Basic Authentication to etcd endpoints
    ip_masq: Install IP masquerade rules for traffic outside of flannel subnet
    subnet_file: Path to flannel subnet file to write out
    interface: Interface (name or IP) that should be used for inter-host communication
    public_ip: IP accessible by other nodes for inter-host communication
'
  local root_coreos_locksmith_='endpoint: Comma separated list of etcd endpoints
    etcd_cafile: Path to CA file used for TLS communication with etcd
    etcd_certfile: Path to certificate file used for TLS communication with etcd
    etcd_keyfile: Path to private key file used for TLS communication with etcd
    group: Name of the reboot group in which this instance belongs
    window_start: Start time of the reboot window
    window_length: Duration of the reboot window
    etcd_username: Username for Basic Authentication to etcd endpoints
    etcd_password: Password for Basic Authentication to etcd endpoints
'
  local root_coreos_update_='reboot-strategy: One of "reboot", "etcd-lock", or "off" for controlling when reboots are issued after an update is performed.
        reboot: Reboot immediately after an update is applied.
        etcd-lock: Reboot after first taking a distributed lock in etcd, this guarantees that only one host will reboot concurrently and that the cluster will remain available during the update.
        off - Disable rebooting after updates are applied (not recommended).
    server: The location of the CoreUpdate server which will be queried for updates. Also known as the omaha server endpoint.
    group: signifies the channel which should be used for automatic updates. This value defaults to the version of the image initially downloaded. (one of "master", "alpha", "beta", "stable")
'
  local root_coreos_units_='name: String representing unit'\''s name. Required.
    runtime: Boolean indicating whether or not to persist the unit across reboots. This is analogous to the --runtime argument to systemctl enable. The default value is false.
    enable: Boolean indicating whether or not to handle the [Install] section of the unit file. This is similar to running systemctl enable <name>. The default value is false.
    content: Plaintext string representing entire unit file. If no value is provided, the unit is assumed to exist already.
    command: Command to execute on unit: start, stop, reload, restart, try-restart, reload-or-restart, reload-or-try-restart. The default behavior is to not execute any commands.
    mask: Whether to mask the unit file by symlinking it to /dev/null (analogous to systemctl mask <name>). Note that unlike systemctl mask, this will destructively remove any existing unit file located at /etc/systemd/system/<unit>, to ensure that the mask succeeds. The default value is false.
    drop-ins: A list of unit drop-ins with the following fields:
        name: String representing unit'\''s name. Required.
        content: Plaintext string representing entire file. Required.'
  local root_users_='name: Required. Login name of user
    gecos: GECOS comment of user
    passwd: Hash of the password to use for this user
    homedir: User'\''s home directory. Defaults to /home/<name>
    no-create-home: Boolean. Skip home directory creation.
    primary-group: Default group for the user. Defaults to a new group created named after the user.
    groups: Add user to these additional groups
    no-user-group: Boolean. Skip default group creation.
    ssh-authorized-keys: List of public SSH keys to authorize for this user
    coreos-ssh-import-github (DEPRECATED): Authorize SSH keys from GitHub user
    coreos-ssh-import-github-users (DEPRECATED): Authorize SSH keys from a list of GitHub users
    coreos-ssh-import-url (DEPRECATED): Authorize SSH keys imported from a url endpoint.
    system: Create the user as a system user. No home directory will be created.
    no-log-init: Boolean. Skip initialization of lastlog and faillog databases.
    shell: User'\''s login shell.
    inactive: Deactivate the user upon creation
    lock-passwd: Boolean. Disable password login for user
    sudo: Entry to add to /etc/sudoers for user. By default, no sudo access is authorized.
    selinux-user: Corresponding SELinux user
    ssh-import-id: Import SSH keys by ID from Launchpad.'
  local root_write__files_='path: Absolute location on disk where contents should be written
    content: Data to write at the provided path
    permissions: Integer representing file permissions, typically in octal notation (i.e. 0644)
    owner: User and group that should own the file written to disk. This is equivalent to the <user>:<group> argument to chown <user>:<group> <path>.
    encoding: Optional. The encoding of the data in content. If not specified this defaults to the yaml document encoding (usually utf-8). Supported encoding types are:
        b64, base64: Base64 encoded content
        gz, gzip: gzip encoded content, for use with the !!binary tag
        gz+b64, gz+base64, gzip+b64, gzip+base64: Base64 encoded gzip content'


  local| grep '^root_'
}

function _cloudconfig_format_spec_list() {
  _cloudconfig_gen_format_spec
        # TODO function spec to var definitions
  local root_=${root:-MISSING}
  local all_vars=$(local| grep '^root_'| cut -d'=' -f1)
  local -i max_path=$(sed 's/__}//g' <<<"$all_vars"| tr -cd '_\r\n'| wc -L)

  local -n cur_node=root_
  for depth in $(seq 1 $max_path); do
    cut -d _ -f-$depth <<<"$all_vars"
  done| sed 's/[^_]$/&_/g'| sort| uniq| \
      while read node_path; do
        local -n cur_node=${node_path}
        if [ -z "$cur_node" ]; then
          echo $depth : $node_path missing
          local -x ${node_path}_='MISSING'
          echo local -x ${node_path}='MISSING'
          # some value for node_path_
        else 
          echo $depth : $node_path exists
          # extract parameters
        fi
      done
}

function _cloudconfig_create_pipes_recur() {
  local -i level=$1
  local -i next_level=$level+1
  local prefix="$2"
  shift 2; [ "$#" -eq 0 ] && return

  for node in $*; do
    echo _cloudconfig_create_pipes_recur $level $node
  done
}

function _cloudconfig_parse_format_spec() {
  eval $(_cloudconfig_gen_format_spec| _prepend 'local ')
  _cloudconfig_create_pipes_recur 0 root_
}

function _cloudconfig_enable_unit() {
  enabled=true _cloudconfig_unit
}

function _cloudconfig_unit_w_content() {
  _cloudconfig_unit
  _content
}

function _cloudconfig_file() {
  local path="$1" perms="$2:-0755" owner="$3:-root" group="$3:-root"

  cat<<EOF |
- path: $path
  permissions: $perms
  owner: $owner:$group
  content: |
EOF
    _indent_spaces 2
  _indent_spaces 8
}

function _gen_cloudconfig() {


    cat<<EOF
#cloud-config

hostname: $hostname

coreos:
    etcd:
        name: $hostname
    units:
      - name: update-engine.service
        enable: false
        mask: true
        command: stop
      - name: locksmithd.service
        enable: false
        mask: true
        command: stop
      - name: systemd-sysctl.service
        command: restart
      - name: etcd.service
        command: start
      - name: sshd.socket
        enable: false
        command: stop
      - name: sshd.service
        enable: true
        command: start
      - name: docker-vmware.service
        content: |
            [Unit]
            Description=Docker container with VMWare Tools
            After=systemd-networkd.service
            Requires=docker.service
            [Service]
            Restart=always
            TimeoutStartSec=10s
            StartLimitInterval=0
            ExecStartPre=-/usr/bin/docker rm vmware-tools
            ExecStart=/usr/bin/docker run --net=host --privileged --name vmware-tools sergeyzh/vmware-tools
            ExecStop=-/usr/bin/docker stop vmware-tools
            ExecStopPost=-/usr/bin/docker rm vmware-tools
            [Install]
            WantedBy=multi-user.target
      - name: docker-object.service
        content: |
            [Unit]
            Description=Docker container with dataservices
            After=systemd-networkd.service
            Requires=docker.service
            [Service]
            Restart=always
            TimeoutStartSec=10s
            StartLimitInterval=0
            ExecStartPre=-/usr/bin/docker rm emcvipr-object
            ExecStart=/usr/bin/docker run --cap-add ALL -v $DataMnt/ss:/dae -v /host:/host -v /var/log/vipr/emcvipr-object:/var/log -v $DataMnt:/data --net=host --name emcvipr-object emcvipr/object:latest
            ExecStop=-/usr/bin/docker stop emcvipr-object
            ExecStopPost=-/usr/bin/docker rm emcvipr-object
            [Install]
            WantedBy=multi-user.target
      - name: docker-registry.service
        content: |
            [Unit]
            Description=Docker container with registry service
            After=systemd-networkd.service
            Requires=docker.service
            [Service]
            Restart=always
            TimeoutStartSec=10s
            StartLimitInterval=0
            ExecStartPre=-/usr/bin/docker rm registry
            ExecStart=/usr/bin/docker run -p 5000:5000 -v /home/core/registry-data:/data --name registry emcvipr/registry
            ExecStop=-/usr/bin/docker stop registry
            ExecStopPost=-/usr/bin/docker rm registry
            [Install]
            WantedBy=multi-user.target
      - name: format-data.service
        command: start
        content: |
            [Unit]
            Description=Formating of the data drive
            ConditionPathExists=!/var/lib/format-data-done 
            [Service]
            Type=oneshot
            RemainAfterExit=yes
            ExecStart=/usr/sbin/wipefs -f /dev/sdb
            ExecStart=/usr/sbin/mkfs.ext4 -F /dev/sdb
            ExecStartPost=/usr/bin/touch /var/lib/format-data-done 
      - name: format-var-log.service
        command: start
        content: |
            [Unit]
            Description=Formating of the data drive
            ConditionPathExists=!/var/lib/format-var-log-done 
            [Service]
            Type=oneshot
            RemainAfterExit=yes
            ExecStart=/usr/sbin/wipefs -f /dev/sdc
            ExecStart=/usr/sbin/mkfs.ext4 -F /dev/sdc
            ExecStartPost=/usr/bin/touch /var/lib/format-var-log-done 
      - name: data.mount
        command: start
        content: |
            [Unit]
            Description=Mounting of the data drive
            Requires=format-data.service
            After=format-data.service
            Before=docker.service
            [Mount]
            What=/dev/sdb
            Where=/data
            Type=ext4
            Options=rw,user_xattr,data=journal
      - name: var-log-vipr.mount
        command: start
        content: |
            [Unit]
            Description=Mounting of the logs drive
            Requires=format-var-log.service
            After=format-var-log.service
            Before=docker.service
            [Mount]
            What=/dev/sdc
            Where=/var/log/vipr
            Type=ext4

users:
  - name: root
    passwd: \$6\$eFLZK/0aE7C9\$.6lmEDtgEVWgQh74WnZbWV6VksJE8mbNsiqZvKLdPHck.Yjix53YCrob35HqoHOD2GHHM8OMu0aBX4Sdf8EUY1
    ssh-authorized-keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDkUrWxLDFBu9OWRXzYN74szcfx7WOzbtfjMnatrB0EkSazR1IYWyEAYowbkNevts8Z1aL/Y5e4uUI1D0j2PJ7OOA0h0ctyDkh5i+n5XP7W0N5fYxN8GBl3+rQVU5gaRLJD3pMNZjvHIfDikIz9Z3jTYWU4FWn7c6xOQTwHx1Ac/Q== root@coreos
  - name: core
    passwd: \$6\$eFLZK/0aE7C9\$.6lmEDtgEVWgQh74WnZbWV6VksJE8mbNsiqZvKLdPHck.Yjix53YCrob35HqoHOD2GHHM8OMu0aBX4Sdf8EUY1
    groups:
      - sudo
      - docker
    ssh-authorized-keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDkUrWxLDFBu9OWRXzYN74szcfx7WOzbtfjMnatrB0EkSazR1IYWyEAYowbkNevts8Z1aL/Y5e4uUI1D0j2PJ7OOA0h0ctyDkh5i+n5XP7W0N5fYxN8GBl3+rQVU5gaRLJD3pMNZjvHIfDikIz9Z3jTYWU4FWn7c6xOQTwHx1Ac/Q== root@coreos
      - ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key

coreos:
    units:
        - name: systemd-networkd.service
          command: try-restart
        - name: docker.service
          command: try-restart
EOF
}
