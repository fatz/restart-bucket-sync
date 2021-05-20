# restart-bucket-sync
Script and container to reupload failed bucket sync objects

## deploy on k8s
either edit the `k8s.yaml` directly or use following yq bash script:

```
export NAMESPACE = "mynamespace"
export RESYNC_AWS_ROLE_NAME="arn:aws:iam::123456789:role/my-s3-role"
# export RESYNC_AWS_SESSION_NAME="myspecialsessionname"
export RESYNC_INVENTORY_BUCKET_NAME="mybucket"
export RESYNC_INVENTORY_FILE_PATH="mybucketname/status-inventory/data/1234.csv.gz"
# export RESYNC_DRY_RUN = false

yq e ".metadata.annotations.\"iam.amazonaws.com/role\" = \"${RESYNC_AWS_ROLE_NAME}\" | .metadata.annotations.\"iam.amazonaws.com/session-name\" = \"${RESYNC_AWS_SESSION_NAME:-s3resync}\" | .data.inventory_bucket_name = \"${RESYNC_INVENTORY_BUCKET_NAME}\" | .data.inventory_file_path = \"${RESYNC_INVENTORY_FILE_PATH}\" | .data.dry_run = \"${RESYNC_DRY_RUN:-true}\"" k8s.yaml | kubectl -n $NAMESPACE apply
```
