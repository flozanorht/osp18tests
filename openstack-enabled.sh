#!/bin/sh

# Simple script to display the status of OpenStack control plane services on OpenShift

ocpcp="openstack-basic"
services="ceilometer cinder dns galera glance heat horizon ironic keystone manila mariadb memcached neutron nova octavia ovn placement rabbitmq redis swift"

printf "%-12s: %-7s - %s\n" SERVICE ENABLED READY
# Need to re-test this logic with all services enabled.
for s in $services; do
  conditions="${s^}"
  if [ "$s" = "glance" -o "$s" = "cinder" -o "$s" = "neutron" -o "$s" = "nova" -o "$s" = "swift" -o "$s" = "heat" -o "$s" = "horizon" ]; then
    conditions="${s^} Expose${s^}"
  elif [ "$s" = "keystone" -o "$s" = "placement" ]; then
    conditions="${s^}API Expose${s^}API"
  elif [ "$s" = "ovn" ]; then
    conditions="OVN"
  elif [ "$s" = "rabbitmq" ]; then
    conditions="RabbitMQ"
  elif [ "$s" = "mariadb" ]; then
    conditions="MariaDB"
  elif [ "$s" = "dns" ]; then
    # how strange... no condition for dns (Designate?) is it because of my issue with Glance?
    # no, it's because it's not enabled. so my logic may be wrong for it and also for galera, redis, and other services which are disabled
    conditions=""
  fi
  status=$( oc get openstackcontrolplane $ocpcp -n openstack -o jsonpath="{.spec.$s.enabled}" )
  printf "%-12s: %-7s" ${s^} $status
  #echo -n "$conditions"
  if [ "$status" = "true" ]; then
    echo -n " - "
    first="yes"
    for c in $conditions; do
      if [ -z "$first" ]; then
        echo -n ", "
      fi
      condition="OpenStackControlPlane${c}Ready"
      status=$( oc get openstackcontrolplane $ocpcp -n openstack -o jsonpath="{.status.conditions[?(.type=='$condition')].status}" )
      printf "%s: %s" ${c} $status
      first=""
    done
  fi
  echo
done

# $ oc get openstackcontrolplane openstack-basic -n openstack -o jsonpath='{.status.conditions[?(.status=="True")].type}'
# OpenStackControlPlaneCeilometerReady OpenStackControlPlaneCinderReady OpenStackControlPlaneClientReady OpenStackControlPlaneExposeCinderReady OpenStackControlPlaneExposeKeystoneAPIReady OpenStackControlPlaneExposeNeutronReady OpenStackControlPlaneExposeNovaReady OpenStackControlPlaneExposePlacementAPIReady OpenStackControlPlaneExposeSwiftReady OpenStackControlPlaneKeystoneAPIReady OpenStackControlPlaneMariaDBReady OpenStackControlPlaneMemcachedReady OpenStackControlPlaneNeutronReady OpenStackControlPlaneNovaReady OpenStackControlPlaneOVNReady OpenStackControlPlanePlacementAPIReady OpenStackControlPlaneRabbitMQReady OpenStackControlPlaneSwiftReady[student@workstation ~]$ 
# $ oc get openstackcontrolplane openstack-basic -n openstack -o jsonpath='{.status.conditions[?(.status=="False")].type}'
# Ready OpenStackControlPlaneGlanceReady
