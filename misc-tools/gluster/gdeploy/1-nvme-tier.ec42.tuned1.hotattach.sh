#!/bin/bash

# This is intended to be run on one gluster node after the preconfig gdeploy configs are run

gluster volume tier 1nvme-ec42 attach replica 2 n0:/rhgs/hotbricks/1nvme-ec42-hot n1:/rhgs/hotbricks/1nvme-ec42-hot n2:/rhgs/hotbricks/1nvme-ec42-hot n3:/rhgs/hotbricks/1nvme-ec42-hot n4:/rhgs/hotbricks/1nvme-ec42-hot n5:/rhgs/hotbricks/1nvme-ec42-hot 

gluster volume tier 1nvme-ec42 start force
