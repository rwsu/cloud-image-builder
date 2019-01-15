#!/usr/bin/env bash
set -x

if [ ! -d kubevirt-ansible ]; then
  git clone https://github.com/kubevirt/kubevirt-ansible

  sed -i.bak "s@kubectl taint nodes {{ ansible_fqdn }} node-role.kubernetes.io/master:NoSchedule- || :@kubectl taint nodes --all node-role.kubernetes.io/master-@"  kubevirt-ansible/roles/kubernetes-master/templates/deploy_kubernetes.j2

  # set platform
  sed -i.bak "s/platform: openshift/platform: kubernetes/" kubevirt-ansible/vars/all.yml

  #Fix for missing {{ }}
  sed -i.bak "s/weavenet.stdout/\"{{ weavenet.stdout }}\"/" kubevirt-ansible/roles/kubernetes-master/tasks/main.yml

fi

export KUBEVIRT_VERSION=0.13.0
cd image-files
# used during first-boot to decide which version of KubeVirt to install
echo $KUBEVIRT_VERSION > kubevirt-version
[ -f virtctl ] || curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/v$KUBEVIRT_VERSION/virtctl-v$KUBEVIRT_VERSION-linux-amd64
chmod +x virtctl
cd ..

# for use by gcp image publish
echo $KUBEVIRT_VERSION > kubevirt-version
pwd

$PACKER build -debug -machine-readable --force $PACKER_BUILD_TEMPLATE | tee build.log
echo "AWS_TEST_AMI=`egrep -m1 -oe 'ami-.{8}' build.log`" >> job.props
