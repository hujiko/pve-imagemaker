# -*- mode: ruby -*-
# vi: set ft=ruby :

DISK = ENV['DISK_IMAGE']
DISK_SIZE_GB=10
CODENAME = ENV['CODENAME'].downcase
BOXNAME = ENV['BOXNAME']
CONTROLLER_NAME = 'SCSI'
PORT = 2
DEVICE = 0
FILE_ROOT = File.dirname(File.expand_path(__FILE__))
DISK_ID_FILE = File.join(FILE_ROOT, CODENAME.gsub('/', '') + '.disk.id')
DISK_SIZE = (10 * 1024).to_s
VM_UUID_FILE = File.join(FILE_ROOT, CODENAME.gsub('/', '') + '.vm.uuid')


class VagrantPlugins::ProviderVirtualBox::Action::SetName
  alias_method :original_call, :call
  def call(env)
      driver = env[:machine].provider.driver
      uuid = driver.instance_eval { @uuid }
      IO.write(VM_UUID_FILE, uuid)
      original_call(env)
  end
end

Vagrant.configure(2) do |config|
  config.vm.provider "virtualbox" do |vb|
    vb.customize ['createmedium', 'disk', '--format', 'vdi', '--filename', DISK, '--size', DISK_SIZE_GB * 1024]
    vb.customize ['storageattach', :id, '--storagectl', CONTROLLER_NAME, '--port', PORT, '--device', DEVICE, '--type', 'hdd', '--medium', DISK]
  end
  config.vm.box = BOXNAME
  config.vm.define CODENAME.gsub('/', '')
  config.ssh.insert_key = false
  config.vm.synced_folder '.', '/vagrant', type: 'rsync',
    rsync__exclude: %w(
      .git/
      .gitignore
      .gitmodules
      *.vmdk
      *.vmx
      *.vdi
      *.qcow2
    )

  config.vbguest.auto_update = false if Vagrant.has_plugin?('vagrant-vbguest')

  config.trigger.after :halt do |trigger|
    trigger.info = "Detach disk from vm."
    trigger.run = {
      inline: <<-SHELL
        /bin/bash -c \"VBoxManage --nologo storageattach \$(cat #{VM_UUID_FILE}) --storagectl #{CONTROLLER_NAME} --port #{PORT.to_s} --device #{DEVICE.to_s} --type hdd --medium none\"
        /bin/bash -c \"echo Storage detatched.\"
        /bin/bash -c \"VBoxManage --nologo closemedium disk #{DISK}\"
        /bin/bash -c \"echo Disk medium closed.\"
      SHELL
    }
  end
end
