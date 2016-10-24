#!/bin/bash

# This is intended to be run on one gluster node after the preconfig gdeploy configs are run

gluster volume tier 1nvme-distrep3x2 attach replica 2 n0:/rhgs/hotbricks/1nvme-distrep3x2-hot n1:/rhgs/hotbricks/1nvme-distrep3x2-hot n2:/rhgs/hotbricks/1nvme-distrep3x2-hot n3:/rhgs/hotbricks/1nvme-distrep3x2-hot n4:/rhgs/hotbricks/1nvme-distrep3x2-hot n5:/rhgs/hotbricks/1nvme-distrep3x2-hot 

gluster volume tier 1nvme-distrep3x2 start force
