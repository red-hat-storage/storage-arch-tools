#!/usr/bin/python

import boto
import boto.s3.connection
access_key = 'S3user1' 		# Add your access key
secret_key = 'S3user1key'	# Add your secret key

conn = boto.connect_s3(
    aws_access_key_id = access_key,
    aws_secret_access_key = secret_key,
    host = 'ceph-rgw1:80',	# Add your RGW host and Port number
    is_secure=False,
    calling_format = boto.s3.connection.OrdinaryCallingFormat(),
    )
objectCount = 0
bucketCount = 0

for bucket in conn.get_all_buckets():
	bucketCount += 1

	for key in bucket.list():
		objectCount += 1

print "{bucketCount},{objectCount}".format(
        bucketCount = bucketCount,
	objectCount = objectCount
)
