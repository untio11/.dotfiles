import * as gcp from "@pulumi/gcp";
import * as pulumi from "@pulumi/pulumi";

// 0. Enabled Google Cloud APIs for this project
const storageApi = new gcp.projects.Service("storage-api", {
    service: "storage.googleapis.com",
    disableOnDestroy: false,
});

const iamApi = new gcp.projects.Service("iam-api", {
    service: "iam.googleapis.com",
    disableOnDestroy: false,
});

const cloudResourceManagerApi = new gcp.projects.Service(
    "cloudresourcemanager-api",
    {
        service: "cloudresourcemanager.googleapis.com",
        disableOnDestroy: false,
    },
);

const documentAiApi = new gcp.projects.Service("documentai-api", {
    service: "documentai.googleapis.com",
    disableOnDestroy: false,
});

const apiKeysApi = new gcp.projects.Service("apikeys-api", {
    service: "apikeys.googleapis.com",
    disableOnDestroy: false,
});

// 1. Off-site Restic backup bucket in the Netherlands (europe-west4)
const backupBucket = new gcp.storage.Bucket("gathering-hub-restic", {
    location: "EUROPE-WEST4",
    storageClass: "STANDARD",
    uniformBucketLevelAccess: true,
    publicAccessPrevention: "enforced",
    // Disable 7-day soft-delete retention so `restic forget --prune` immediately frees billable storage:
    softDeletePolicy: {
        retentionDurationSeconds: 0,
    },
});

// 2. Dedicated Service Account for gathering-hub Restic backups
const resticSa = new gcp.serviceaccount.Account("restic-gathering-hub", {
    accountId: "restic-gathering-hub",
    displayName: "Restic Backup (gathering-hub)",
    description: "Dedicated service account for encrypted Restic backups from gathering-hub",
});

// 3. Grant the Service Account access ONLY to this specific backup bucket
new gcp.storage.BucketIAMMember("restic-bucket-object-admin", {
    bucket: backupBucket.name,
    role: "roles/storage.objectAdmin",
    member: pulumi.interpolate`serviceAccount:${resticSa.email}`,
});

// 4. Generate a JSON key for the Service Account (stored encrypted in Pulumi state)
const resticSaKey = new gcp.serviceaccount.Key("restic-gathering-hub-key", {
    serviceAccountId: resticSa.name,
});

// 5. Document AI OCR processor for Paperless-GPT (europe-west2)
const paperlessOcrProcessor = new gcp.essentialcontacts.DocumentAiProcessor(
    "general-doc-ocr",
    {
        location: "europe-west2",
        displayName: "general-doc-ocr",
        type: "OCR_PROCESSOR",
    },
);

// 6. Dedicated Service Account and IAM binding for Paperless-GPT Document AI OCR
const paperlessDocAiSa = new gcp.serviceaccount.Account(
    "paperless-doc-ai-sa",
    {
        accountId: "paperless-doc-ai-sa",
        displayName: "paperless-doc-ai-sa",
        description: "Used for Paperless OCR",
        project: "robotic-circle-456517-e7",
    },
);

new gcp.projects.IAMMember(
    "paperless-doc-ai-user",
    {
        project: "robotic-circle-456517-e7",
        role: "roles/documentai.apiUser",
        member: pulumi.interpolate`serviceAccount:${paperlessDocAiSa.email}`,
    },
    { dependsOn: [cloudResourceManagerApi] },
);

const paperlessDocAiSaKey = new gcp.serviceaccount.Key(
    "paperless-doc-ai-sa-key",
    {
        serviceAccountId: paperlessDocAiSa.name,
    },
);

export const bucketName = backupBucket.name;
export const bucketUrl = pulumi.interpolate`gs:${backupBucket.name}:/`;
export const serviceAccountEmail = resticSa.email;
export const serviceAccountKeyJson = pulumi
    .secret(resticSaKey.privateKey)
    .apply((k) => Buffer.from(k, "base64").toString("utf-8"));
export const paperlessOcrProcessorId = paperlessOcrProcessor.name;
export const paperlessDocAiKeyJson = pulumi
    .secret(paperlessDocAiSaKey.privateKey)
    .apply((k) => Buffer.from(k, "base64").toString("utf-8"));
