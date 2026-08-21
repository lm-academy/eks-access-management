terraform {
  # Remote state in S3. This is a partial configuration: the bucket and key are
  # chosen per clone, either by adding both attributes to this block or by
  # passing them at init time with -backend-config (see the README).
  # use_lockfile enables native S3 state locking, with no DynamoDB table
  # required (Terraform 1.10+).
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}
