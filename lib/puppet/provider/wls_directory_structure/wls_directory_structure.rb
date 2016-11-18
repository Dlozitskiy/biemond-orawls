require 'fileutils'

Puppet::Type.type(:wls_directory_structure).provide(:wls_directory_structure) do

  def configure
    name            = resource[:name]
    oracle_base     = resource[:oracle_base_dir]
    ora_inventory   = resource[:ora_inventory_dir]
    middleware_home = resource[:ora_middleware_home]
    temp_folder     = resource[:temp_directory]
    download_folder = resource[:download_dir]
    user            = resource[:os_user]
    group           = resource[:os_group]

    Puppet.info "configure oracle folders for #{name}"

    Puppet.info "create the following directories: #{oracle_base}, #{middleware_home}, #{ora_inventory}, #{download_folder}"
    
    make_directory oracle_base
    ownened_by_oracle oracle_base, user, group

    make_directory middleware_home
    ownened_by_oracle middleware_home, user, group

    make_directory ora_inventory
    ownened_by_oracle ora_inventory, user, group

    make_directory temp_folder
    ownened_by_oracle temp_folder, user, group

    make_directory download_folder
    allow_everybody download_folder

  end

  def make_directory(path)
    Puppet.info "creating directory #{path}"
    FileUtils.mkdir_p path
  end

  def ownened_by_oracle(path, user, group)
    Puppet.info "Setting oracle ownership for #{path} with 0775"
    FileUtils.chmod_R 0775, path
    FileUtils.chown_R user, group, path
  end

  def allow_everybody(path)
    Puppet.info "Setting public permissions 0777 for #{path}"
    FileUtils.chmod 0777, path
  end

end
