require 'easy_type'
require 'utils/wls_access'
require 'utils/settings'
require 'facter'

module Puppet
  #
  newtype(:wls_saf_imported_destination) do
    include EasyType
    include Utils::WlsAccess

    desc "This resource allows you to manage a SAF imported destinations in a JMS Module of an WebLogic domain."

    ensurable

    set_command(:wlst)
  
    to_get_raw_resources do
      Puppet.info "index #{name}"
      environment = { "action"=>"index","type"=>"wls_saf_imported_destination"}
      wlst template('puppet:///modules/orawls/providers/wls_saf_imported_destination/index.py.erb', binding), environment
    end

    on_create  do | command_builder |
      Puppet.info "create #{name} "
      template('puppet:///modules/orawls/providers/wls_saf_imported_destination/create.py.erb', binding)
    end

    on_modify  do | command_builder |
      Puppet.info "modify #{name} "
      template('puppet:///modules/orawls/providers/wls_saf_imported_destination/modify.py.erb', binding)
    end

    on_destroy  do | command_builder |
      Puppet.info "destroy #{name} "
      template('puppet:///modules/orawls/providers/wls_saf_imported_destination/destroy.py.erb', binding)
    end

    def self.title_patterns
      identity = lambda {|x| x}
      [
        [
          /^((.*):(.*))$/,
          [
            [ :name, identity ],
            [ :jmsmodule, identity ],
            [ :imported_destination_name, identity ]
          ]
        ],
        [
          /^([^=]+)$/,
          [
            [ :name, identity ]
          ]
        ]
      ]
    end

    parameter :name
    parameter :jmsmodule
    parameter :imported_destination_name
    property  :errorhandling
    property  :remotecontext
    property  :jndiprefix
    property  :timetolivedefault
    property  :usetimetolivedefault
    property  :defaulttargeting
    property  :subdeployment

   end
end