#!/usr/bin/env bash

# =============================================================================
# setup_aws_resources.sh
# Creates the S3 bucket, S3 prefixes, and IAM role for Snowflake.
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------

BUCKET_NAME="sparkify-dw-bucket-hamza"
AWS_REGION="us-east-1"
ROLE_NAME="sparkify_snowflake_s3_role"
POLICY_NAME="sparkify_snowflake_s3_policy"

# Always resolve files relative to this script's location.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TRUST_POLICY="$(cygpath -w "${SCRIPT_DIR}/trust_policy.json")"
IAM_POLICY="$(cygpath -w "${SCRIPT_DIR}/iam_policy.json")"

# -----------------------------------------------------------------------------
# CHECK REQUIRED FILES
# -----------------------------------------------------------------------------

if [[ ! -f "${TRUST_POLICY}" ]]; then
    echo "ERROR: trust_policy.json not found:"
    echo "${TRUST_POLICY}"
    exit 1
fi

if [[ ! -f "${IAM_POLICY}" ]]; then
    echo "ERROR: iam_policy.json not found:"
    echo "${IAM_POLICY}"
    exit 1
fi

# -----------------------------------------------------------------------------
# STEP 1: CREATE S3 BUCKET
# -----------------------------------------------------------------------------

echo "=== Step 1: Create S3 bucket ==="

if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
    echo "Bucket already exists: ${BUCKET_NAME}"
else
    aws s3api create-bucket \
        --bucket "${BUCKET_NAME}" \
        --region "${AWS_REGION}"

    echo "Bucket created: ${BUCKET_NAME}"
fi

# -----------------------------------------------------------------------------
# STEP 2: CREATE S3 PREFIXES
# -----------------------------------------------------------------------------

echo "=== Step 2: Create S3 folders ==="

aws s3api put-object \
    --bucket "${BUCKET_NAME}" \
    --key "data/log_data/"

aws s3api put-object \
    --bucket "${BUCKET_NAME}" \
    --key "data/song_data/"

# -----------------------------------------------------------------------------
# STEP 3: CREATE IAM ROLE
# -----------------------------------------------------------------------------

echo "=== Step 3: Create IAM role ==="

if aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
    echo "IAM role already exists: ${ROLE_NAME}"
else
    aws iam create-role \
        --role-name "${ROLE_NAME}" \
        --assume-role-policy-document "file://${TRUST_POLICY}"

    echo "IAM role created: ${ROLE_NAME}"
fi

# -----------------------------------------------------------------------------
# STEP 4: ATTACH INLINE S3 POLICY
# -----------------------------------------------------------------------------

echo "=== Step 4: Attach S3 permissions ==="

aws iam put-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-name "${POLICY_NAME}" \
    --policy-document "file://${IAM_POLICY}"

echo "S3 permissions attached."

# -----------------------------------------------------------------------------
# STEP 5: PRINT ROLE ARN
# -----------------------------------------------------------------------------

echo "=== Step 5: Snowflake IAM Role ARN ==="

ROLE_ARN=$(aws iam get-role \
    --role-name "${ROLE_NAME}" \
    --query 'Role.Arn' \
    --output text)

echo "${ROLE_ARN}"
echo ""

echo "=== Done ==="
echo "Bucket: s3://${BUCKET_NAME}"
echo "Log data: s3://${BUCKET_NAME}/data/log_data/"
echo "Song data: s3://${BUCKET_NAME}/data/song_data/"
echo "Role ARN: ${ROLE_ARN}"