# Filevine v2 API — extracted surface

> Generated from the committed specs (`docs/openapi/FV.App.API.json`, `docs/openapi/FV.Identity.API.json`) on 2026-06-20.
> This is a derived index for navigation; the JSON specs remain the source of truth. Regenerate with `scripts/extract_api_surface.py`.

- **Gateway host:** `api.filevineapp.com`  •  base path `/`  •  schemes `['https']`
- **Spec:** Swagger 2.0 — "Filevine Api Gateway" v2.0.0
- **222 paths**, **289 operations**, across **41 resource families**, 310 definitions

## Gotchas (read before coding resources)

- 221 of 222 paths are under `/fv-app/v2` (no `/core` prefix exists in the gateway spec). Exception(s): `/fv-app/vitals`.
- **Paths are case-sensitive and inconsistently cased** — e.g. `/fv-app/v2/Projects` (list/create) vs `/fv-app/v2/projects/{projectid}` (archive). Even path-parameter names vary (`{projectId}` vs `{projectid}`). Use each path **verbatim** from the spec; do not normalize casing.
- The two required tenant headers (`x-fv-orgid`, `x-fv-userid`) are declared per-operation, not globally — but they appear on virtually every op; send them on all gateway calls.

## Authentication & required headers

- Global security: bearer token in the **`Authorization`** header (Enter `Bearer ` followed by the access token).
- **288 operations also require** the `x-fv-orgid` and `x-fv-userid` headers.
- No request signing/HMAC in the gateway flow. Mint the bearer token via the Identity API (below).

## Pagination contract

Paginated list endpoints (**48 GET endpoints**) accept `offset` (default 0), `limit` (default 50), and optional `requestedFields` (comma-separated field projection), plus per-endpoint filters.
Responses wrap results in an `ItemList…` object with **PascalCase** keys:

| Field | Type | Meaning |
|-------|------|---------|
| `Items` | array | the page of records |
| `Count` | integer | number of items in this response |
| `Offset` | integer | echoed offset |
| `Limit` | integer | echoed limit |
| `HasMore` | boolean | more pages exist |
| `LastID` | integer | last record id (cursor-style continuation on some endpoints) |
| `RequestedFields` | string | echoed field projection |
| `Links` | object | string-map of relative URLs (e.g. `self`, `next`, `previous`) |

Iterate by following `Links.next` (or incrementing `offset += limit`) while `HasMore` is true.

## Resource families

| Family (tag) | # ops |
|--------------|-------|
| Appointments | 5 |
| Billing: Billing Codes | 3 |
| Billing: Billing Items | 15 |
| Billing: Billing Settings and Vitals | 8 |
| Billing: FV Payments | 5 |
| Billing: Invoice Templates | 10 |
| Billing: Invoices | 20 |
| Billing: Project Funds | 5 |
| Billing: Rate Schedules | 10 |
| Billing: Timekeeper Classifications | 1 |
| Billing: Transactions | 14 |
| Collection Sections | 5 |
| Comments | 4 |
| Contact Types | 2 |
| Contacts (Custom) | 4 |
| Contacts (Legacy) | 11 |
| Customs | 8 |
| Data Connector | 4 |
| Deadline Chain Types | 1 |
| Documents | 21 |
| Folders | 7 |
| Forms (Static Sections) | 2 |
| Images | 1 |
| Initializers | 9 |
| Mailroom | 2 |
| Mass Update | 2 |
| Notes | 10 |
| Org Teams | 21 |
| Partner Id | 6 |
| Project Activity | 5 |
| Project Contacts | 4 |
| Project Deadline Chains | 6 |
| Project Deadlines | 5 |
| Project Types | 6 |
| Projects | 12 |
| Reports | 2 |
| Share Links | 4 |
| Task | 13 |
| Users | 9 |
| Vitals | 1 |
| Webhooks | 6 |

## Endpoints by family

### Appointments

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Appointments/{appointmentId}` | get-appointment |  | Get Appointment |
| PATCH | `/fv-app/v2/Appointments/{appointmentId}` | update-appointment |  | Update Appointment |
| DELETE | `/fv-app/v2/Appointments/{appointmentId}` | delete-appointment |  | Delete Appointment |
| GET | `/fv-app/v2/Projects/{projectId}/Appointments` | get-project-appointment-list | 📄 | Get Project Appointment List |
| POST | `/fv-app/v2/Projects/{projectId}/Appointments` | create-project-appointment |  | Create Project Appointment |

### Billing: Billing Codes

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Billing/AvailableBillingCodes` | get-org-billing-codes |  | Get Org Billing Codes |
| POST | `/fv-app/v2/Billing/BillingCodeSet/{billingCodeSetId}/BillingCodes` | add-billing-codes |  | Add Codes to a Code Set |
| GET | `/fv-app/v2/Billing/{projectId}/AvailableBillingCodes` | get-project-billing-codes |  | Get Project Billing Codes |

### Billing: Billing Items

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| PUT | `/fv-app/v2/AccountingSync` | update-accounting-sync |  | Sync Billing Items |
| PUT | `/fv-app/v2/Billing` | create-update-billing-item |  | [Deprecated] Create/Update Billing Item |
| DELETE | `/fv-app/v2/Billing/Delete/BillingItem/{billingItemId}` | delete-billing-item |  | Delete a Billing Item |
| GET | `/fv-app/v2/Billing/org` | get-org-billing-items | 📄 | [Deprecated] Get Org Billing Items |
| GET | `/fv-app/v2/Billing/project/{projectId}` | get-project-billing-items2 | 📄 | [Deprecated] Get Project Billing Items |
| PUT | `/fv-app/v2/BillingItem` | new-create-update-billing-item |  | [Deprecated] Create/Update Billing Item |
| GET | `/fv-app/v2/billing/projects/{projectID}/billing-items/{billingItemID}` | get-billing-item |  | Get a Billing Item |
| GET | `/fv-app/v2/billingitem/org` | new-get-org-billing-items | 📄 | Get Org Billing Items |
| GET | `/fv-app/v2/billingitem/projects/{projectId}` | get-project-billing-items | 📄 | Get Project Billing Items |
| PUT | `/fv-app/v2/billingitem/{billingItemId}/note` | set-note-on-billing-item |  | Assign a Note to a Billing Item |
| DELETE | `/fv-app/v2/billingitem/{projectId}/note/{billingItemId}` | remove-note-from-billing-item |  | Remove a Note from a Billing Item |
| POST | `/fv-app/v2/billingitems/{billingItemId}/attachments` | add-attachments-to-project-billing-items |  | Add Attachments to a Project Billing Item |
| DELETE | `/fv-app/v2/billingitems/{billingItemId}/attachments` | remove-attachments-to-project-billing-items |  | Remove Attachments from Project Billing Items |
| POST | `/fv-app/v2/projects/{projectId}/BillingItem` | new-create-billing-item |  | Create a Billing Item |
| PUT | `/fv-app/v2/projects/{projectId}/BillingItem/{billingItemId}` | new-update-billing-item |  | Update a Billing Item |

### Billing: Billing Settings and Vitals

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Billing/org/Settings` | get-org-billing-settings |  | Get Org Billing Settings |
| GET | `/fv-app/v2/Billing/projectbillingsettings/{projectId}/clientMatterId` | get-client-matter-Id |  | Get Client Matter ID |
| POST | `/fv-app/v2/Billing/projectbillingsettings/{projectId}/clientMatterId` | set-client-matter-Id |  | Set Client Matter ID |
| PUT | `/fv-app/v2/Billing/projects/{projectID}/billing-settings` | update-project-billing-settings |  | Update Project Billing Settings |
| GET | `/fv-app/v2/Billing/projects/{projectID}/billingVitals` | get-billing-vitals |  | Get Project Billing Vitals |
| GET | `/fv-app/v2/Billing/projects/{projectID}/billingsettings` | get-project-billing-settings |  | Get Project Billing Settings |
| GET | `/fv-app/v2/Billing/projects/{projectID}/projectFundSettings` | project-fund-settings-get-public |  | Get Project Fund Settings for a Project |
| PUT | `/fv-app/v2/Billing/projects/{projectID}/projectFundSettings` | project-fund-settings-set-public |  | Update Project Fund Settings for a Project |

### Billing: FV Payments

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Billing/invoice/{invoiceID}/paymentlink` | get-payment-link |  | Get a Payment Link for an Invoice |
| GET | `/fv-app/v2/billing/account-mappings` | get-org-deposit-destinations |  | Get Org FV Payments Accounts Mapped |
| GET | `/fv-app/v2/billing/account-mappings/list` | get-available-org-deposit-destinations |  | Get Org FV Payments Accounts Available to Be Mapped |
| GET | `/fv-app/v2/billing/projects/{projectID}/payment-link` | get-project-open-payment-link |  | Get an Open-Ended Payment Link for a Project |
| GET | `/fv-app/v2/billing/projects/{projectId}/account-mappings` | get-project-deposit-destinations |  | Get Project FV Payments Accounts Mapped |

### Billing: Invoice Templates

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/billing/invoice-templates` | get-invoice-templates |  | Get Invoice Templates for an Org |
| POST | `/fv-app/v2/billing/invoice-templates` | add-invoice-template |  | Add an Invoice Template |
| POST | `/fv-app/v2/billing/invoice-templates/org-default/{templateID}` | set-invoice-template-as-default |  | Set a Default Invoice Template for an Org |
| PUT | `/fv-app/v2/billing/invoice-templates/unset-org-default` | unset-invoice-template-org-defaults |  | Unset the Default Invoice Template for an Org |
| GET | `/fv-app/v2/billing/invoice-templates/{templateID}` | get-invoice-template |  | Get an Invoice Template |
| PUT | `/fv-app/v2/billing/invoice-templates/{templateID}` | edit-invoice-template |  | Edit an Invoice Template |
| DELETE | `/fv-app/v2/billing/invoice-templates/{templateID}` | delete-invoice-template-from-org |  | Delete an Invoice Template from an Org |
| GET | `/fv-app/v2/billing/project/{projectID}/invoice-templates` | get-project-default-invoice-template |  | Get the Default Invoice Template for a Project |
| DELETE | `/fv-app/v2/billing/project/{projectID}/invoice-templates` | delete-invoice-template-as-project-default |  | Unset the Default Invoice Template for a Project |
| PUT | `/fv-app/v2/billing/project/{projectID}/invoice-templates/{templateID}` | set-invoice-template-as-project-default |  | Set a Default Invoice Template for a Project |

### Billing: Invoices

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/billing/invoices` | get-org-invoices | 📄 | [Deprecated] Get Org Invoices |
| PUT | `/fv-app/v2/billing/invoices` | create-or-update-invoice |  | [Deprecated] Create/Update Invoice |
| PUT | `/fv-app/v2/billing/invoices/description` | update-invoice-description |  | Update Invoice Description |
| PUT | `/fv-app/v2/billing/invoices/status` | update-invoice-status |  | Update Invoice Status |
| PUT | `/fv-app/v2/billing/invoices/void` | void-invoice |  | Void a Project Invoice |
| PUT | `/fv-app/v2/billing/invoices/writeoff` | write-off-invoice |  | Write Off a Project Invoice |
| POST | `/fv-app/v2/billing/invoices/{invoiceID}/approve` | public-approve-invoice |  | Approve an Invoice |
| POST | `/fv-app/v2/billing/invoices/{invoiceID}/mark-as-sent` | mark-as-sent-invoice |  | Mark a Project Invoice as Sent |
| POST | `/fv-app/v2/billing/invoices/{invoiceID}/send-for-approval` | public-send-invoice-for-approval |  | Send an Invoice for Approval |
| GET | `/fv-app/v2/billing/invoices/{invoiceId}` | get-invoice |  | [Deprecated] Get Invoice |
| GET | `/fv-app/v2/billing/invoices/{invoiceId}/pdf` | get-invoice-pdf |  | Get an Invoice PDF |
| GET | `/fv-app/v2/billing/projects/{projectId}/invoices` | get-project-invoices | 📄 | [Deprecated] Get Project Invoices |
| GET | `/fv-app/v2/billingitem/invoices` | new-get-org-invoices | 📄 | Get Org Invoices |
| PUT | `/fv-app/v2/billingitem/invoices` | new-create-or-update-invoice |  | [Deprecated] Create/Update Invoice |
| GET | `/fv-app/v2/billingitem/invoices/{invoiceId}` | new-get-single-invoice |  | Get an Invoice |
| GET | `/fv-app/v2/billingitem/projects/{projectId}/invoices` | new-get-project-invoices | 📄 | Get Project Invoices |
| DELETE | `/fv-app/v2/projects/{projectID}/invoices/{invoiceID}` | delete-invoice |  | Delete an Invoice |
| POST | `/fv-app/v2/projects/{projectId}/invoices` | new-create-invoice |  | Create an Invoice |
| PUT | `/fv-app/v2/projects/{projectId}/invoices/{invoiceId}` | new-update-invoice |  | Update an Invoice |
| POST | `/fv-app/v2/projects/{projectId}/invoices/{invoiceId}/finalize` | public-api-invoice-finalize |  | Finalize an Invoice |

### Billing: Project Funds

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Billing/projects/{projectID}/funds` | get-funds-balance |  | Get Project Fund Balance |
| POST | `/fv-app/v2/Billing/projects/{projectID}/funds` | add-fund |  | Create Project Fund Transaction |
| GET | `/fv-app/v2/Billing/projects/{projectID}/funds/{projectFundID}` | get-fund-transaction |  | Get a Project Fund Transaction |
| PUT | `/fv-app/v2/Billing/projects/{projectID}/funds/{projectFundID}/void` | void-fund-transaction |  | Void a Project Fund Transaction |
| GET | `/fv-app/v2/Billing/projects/{projectID}/fundslist` | get-funds-transaction-list | 📄 | Get Project Fund Transactions |

### Billing: Rate Schedules

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Billing/org/rateschedules` | get-org-rate-schedules |  | Get Org Rate Schedules |
| PUT | `/fv-app/v2/Billing/projects/{projectId}/rateschedule/{rateScheduleId}` | set-project-rate-schedule |  | Set a Rate Schedule for a Project |
| POST | `/fv-app/v2/rate-schedules` | create-rate-schedule |  | Create Rate Schedule |
| PUT | `/fv-app/v2/rate-schedules/timekeepers/{userId}` | set-timekeeper-details |  | Set Rate Schedule Timekeeper Details |
| POST | `/fv-app/v2/rate-schedules/{rateScheduleID}/flatfeetemplates` | create-rate-schedule-flatfee-template |  | Create Rate Schedule Flat Fee Template |
| PUT | `/fv-app/v2/rate-schedules/{rateScheduleID}/flatfeetemplates/{flatFeeTemplateID}` | update-rate-schedule-flatfee-template |  | Update Rate Schedule Flat Fee Template |
| DELETE | `/fv-app/v2/rate-schedules/{rateScheduleID}/flatfeetemplates/{flatFeeTemplateID}` | delete-rate-schedule-flatfee-template |  | Delete Rate Schedule Flat Fee Template |
| GET | `/fv-app/v2/rate-schedules/{rateScheduleId}` | get-rate-schedule |  | Get a Rate Schedule |
| PUT | `/fv-app/v2/rate-schedules/{rateScheduleId}` | update-rate-schedule |  | Update Rate Schedule |
| DELETE | `/fv-app/v2/rate-schedules/{rateScheduleId}` | delete-rate-schedule |  | Delete Rate Schedule |

### Billing: Timekeeper Classifications

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/classifications` | get-timekeeper-classifications |  | Get Timekeeper Classifications |

### Billing: Transactions

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| PUT | `/fv-app/v2/Billing/invoice/{invoiceID}/payment` | add-payment-transaction-and-apply-to-invoice |  | [Deprecated] Add Payment and Apply to an Invoice |
| PUT | `/fv-app/v2/Billing/invoices/{invoiceID}/transactions/{transactionID}/{amount}` | apply-payment-transaction-to-invoice |  | Apply a Payment Transaction to an Invoice |
| PUT | `/fv-app/v2/Billing/payment` | create-or-update-payment |  | [Deprecated] Add Payment |
| POST | `/fv-app/v2/Billing/payment/void/{PaymentId}` | void-payment |  | [Deprecated] Void Payment |
| GET | `/fv-app/v2/Billing/payment/{paymentId}` | get-payment |  | [Deprecated] Get Payment |
| GET | `/fv-app/v2/Billing/projects/{projectID}/transactions` | get-transactions-for-project | 📄 | Get Project Transactions |
| GET | `/fv-app/v2/Billing/transactions/{transactionId}` | get-transaction |  | Get a Transaction |
| POST | `/fv-app/v2/billing/projects/{projectID}/payment` | new-create-payment |  | Create a Payment |
| POST | `/fv-app/v2/billing/projects/{projectID}/payment/apply` | new-create-and-apply-payment |  | Create a Payment and Apply it to Invoices |
| PUT | `/fv-app/v2/billing/projects/{projectID}/payment/{transactionID}` | new-update-payment |  | Update a Payment |
| POST | `/fv-app/v2/billing/projects/{projectID}/refund` | new-create-refund |  | Create a Refund |
| PUT | `/fv-app/v2/billing/projects/{projectID}/refund/{transactionID}` | new-update-refund |  | Update a Refund |
| DELETE | `/fv-app/v2/billing/projects/{projectID}/transactions/{transactionID}` | new-void-transaction |  | Void a Transaction |
| DELETE | `/fv-app/v2/billing/projects/{projectID}/unapply-payment` | billing-projects-unapply-payment |  | Unapply a Payment from an Invoice |

### Collection Sections

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Projects/{projectId}/Collections/{selector}` | get-project-collection-item-list | 📄 | Get Project Collection Item List |
| POST | `/fv-app/v2/Projects/{projectId}/Collections/{selector}` | create-collection-item |  | Create Collection Item |
| GET | `/fv-app/v2/Projects/{projectId}/Collections/{selector}/{uniqueId}` | get-collection-item |  | Get Collection Item |
| PATCH | `/fv-app/v2/Projects/{projectId}/Collections/{selector}/{uniqueId}` | update-collection-item |  | Update Collection Item |
| DELETE | `/fv-app/v2/Projects/{projectId}/Collections/{selector}/{uniqueId}` | delete-collection-item |  | Delete Collection Item |

### Comments

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Notes/{noteId}/Comments` | get-comment-list | 📄 | Get Comment List |
| POST | `/fv-app/v2/Notes/{noteId}/Comments` | create-comment |  | Create a note comment |
| GET | `/fv-app/v2/Notes/{noteId}/Comments/{commentId}` | get-comment |  | Get Comment |
| PATCH | `/fv-app/v2/Notes/{noteId}/Comments/{commentId}` | update-comment |  | Update Comment |

### Contact Types

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/ContactTypes` | get-contact-type-list | 📄 | Get Contact Type List |
| POST | `/fv-app/v2/ContactTypes` | create-contact-type |  | Create Contact Type |

### Contacts (Custom)

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Custom-Contacts-Meta` | V2CustomContactsMeta_Get |  | Get Contact Metadata |
| POST | `/fv-app/v2/Custom-Contacts/{contactId}` | V2CustomContacts_Post |  | Create Custom Contact |
| PATCH | `/fv-app/v2/Custom-Contacts/{contactId}` | V2CustomContacts_Patch |  | Update Custom Contact |
| GET | `/fv-app/v2/Custom-Contacts/{contactId}/Custom-Data/{tabId}` | V2CustomContacts_Get |  | Get Custom Contact Tab |

### Contacts (Legacy)

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Contacts` | V2Contacts_Get | 📄 | Get Contact List |
| POST | `/fv-app/v2/Contacts` | V2Contacts_Post |  | Create Contact |
| GET | `/fv-app/v2/Contacts/Countries` | contact-get-countries |  | Get Countries |
| GET | `/fv-app/v2/Contacts/PrimaryLanguages` | contact-get-primary-languages |  | Gets a list of the possible values for the Contact.PrimaryLanguages field |
| DELETE | `/fv-app/v2/Contacts/tags/{tagName}` | remove-tag-contacts |  | Remove a tag from multiple contacts. |
| GET | `/fv-app/v2/Contacts/{contactId}` | V2Contacts_Get2 |  | Get Contact |
| PATCH | `/fv-app/v2/Contacts/{contactId}` | V2Contacts_Patch |  | Update Contact |
| GET | `/fv-app/v2/Contacts/{contactId}/addresses` | V2Contacts_GetAddresses | 📄 | Get a list of addresses associated with a Contact |
| GET | `/fv-app/v2/Contacts/{contactId}/emailaddresses` | V2Contacts_GetEmailAddresses | 📄 | Gets a list of email addresses associated with a Contact |
| GET | `/fv-app/v2/Contacts/{contactId}/phones` | V2Contacts_GetPhones | 📄 | Gets a list of the phones associated with a Contact |
| GET | `/fv-app/v2/Contacts/{contactId}/projects` | V2Contacts_GetProjects | 📄 | Get Projects for a Contact |

### Customs

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| PUT | `/fv-app/v2/CustomFields/{customFieldID}` | update-custom-field |  | [Beta] Update Custom Field |
| DELETE | `/fv-app/v2/CustomFields/{customFieldID}` | remove-custom-field |  | [Beta] Remove Custom Field |
| PUT | `/fv-app/v2/CustomSections/{customSectionID}` | update-custom-section |  | [Beta] Update Custom Section |
| DELETE | `/fv-app/v2/CustomSections/{customSectionID}` | remove-custom-section |  | [Beta] Remove Custom Section |
| POST | `/fv-app/v2/CustomSections/{customSectionID}/CustomFields` | create-custom-field |  | [Beta] Create Custom Field |
| POST | `/fv-app/v2/ProjectTypes/{customProjectTypeID}/sections` | create-custom-section |  | [Beta] Create Custom Section |
| GET | `/fv-app/v2/ProjectTypes/{projectTypeId}/Sections/{selector}` | get-project-type-section |  | Get Project Type Section |
| GET | `/fv-app/v2/ProjectTypes/{projectTypeId}/sections` | get-project-type-section-list | 📄 | Get Project Type Sections List |

### Data Connector

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/data-connector` | get-data-connector-jobs | 📄 | Get Data Connector Jobs |
| POST | `/fv-app/v2/data-connector/enqueue` | enqueue-data-connector-jobPOST |  | Enqueues a Data Connector Job |
| POST | `/fv-app/v2/data-connector/presigned-url` | create-data-connector-pickup-url |  | Create Data Connector Pickup URL |
| GET | `/fv-app/v2/data-connector/status/{jobId}` | enqueue-data-connector-jobGET |  | Get Data Connector Job |

### Deadline Chain Types

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/chaintypes` | get-chain-type-list | 📄 | Get Deadline Chain Type List |

### Documents

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/DocumentSearch` | search-documents | 📄 | Search Documents |
| GET | `/fv-app/v2/DocumentSeries` | get-document-series |  | Get Document Series |
| GET | `/fv-app/v2/DocumentSeries/Meta` | get-document-series-meta |  | Get Document Series Metadata |
| GET | `/fv-app/v2/Documents` | get-document-list | 📄 | Get Document List |
| POST | `/fv-app/v2/Documents` | create-document-url-for-upload |  | Create Document URL for Upload |
| POST | `/fv-app/v2/Documents/batch/download` | batch-retrieve-document-s3-download-link |  | Batch Document Download |
| POST | `/fv-app/v2/Documents/batch/upload` | batch-upload-document |  | Batch Document Upload |
| POST | `/fv-app/v2/Documents/batch/upload/confirm` | V2Documents_ConfirmDocumentUpload |  | Batch Document Upload Confirmation |
| POST | `/fv-app/v2/Documents/copy` | copy-documents |  | Copy documents and folders |
| POST | `/fv-app/v2/Documents/move` | move-documents |  | Move documents and folders |
| DELETE | `/fv-app/v2/Documents/tags/{tagName}` | remove-tag-documents |  | Remove Document Tag |
| GET | `/fv-app/v2/Documents/{documentId}` | get-document |  | Get Document |
| PATCH | `/fv-app/v2/Documents/{documentId}` | update-document-metadata |  | Update Document Metadata |
| DELETE | `/fv-app/v2/Documents/{documentId}` | delete-document |  | Delete Document |
| POST | `/fv-app/v2/Documents/{documentId}/Revisions` | add-document-revision |  | Add Document Revision |
| GET | `/fv-app/v2/Documents/{documentId}/locator` | get-document-download-locator |  | Get Document Download Locator |
| POST | `/fv-app/v2/Documents/{documentId}/lock` | lock-document-for-edit |  | Lock Document |
| POST | `/fv-app/v2/Documents/{documentId}/unlock` | unlock-document |  | Unlock Document |
| GET | `/fv-app/v2/Projects/{projectId}/Documents` | get-project-document-list | 📄 | [Deprecated] Get Project Document List |
| POST | `/fv-app/v2/Projects/{projectId}/Documents/{documentId}` | add-document-to-project |  | Add Document to Project |
| GET | `/fv-app/v2/RecentlyOpenedDocuments` | recent-documents | 📄 | Get Recently Opened Documents |

### Folders

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Folders` | get-folder-list | 📄 | Get Folder List |
| POST | `/fv-app/v2/Folders` | create-folder |  | Create Folder |
| GET | `/fv-app/v2/Folders/list` | get-entire-folder-structure | 📄 | Get Folder Structure |
| GET | `/fv-app/v2/Folders/{folderId}` | get-folder |  | Get Folder |
| PATCH | `/fv-app/v2/Folders/{folderId}` | update-folder |  | Update Folder |
| DELETE | `/fv-app/v2/Folders/{folderId}` | delete-folder |  | Delete Folder |
| GET | `/fv-app/v2/Folders/{folderId}/children` | get-folder-children | 📄 | Get Folder Children |

### Forms (Static Sections)

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Projects/{projectId}/Forms/{selector}` | get-form |  | Get Form |
| PATCH | `/fv-app/v2/Projects/{projectId}/Forms/{selector}` | update-form |  | Update Form |

### Images

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/images/{imageId}` | v2-get-image |  | Get Stored Image |

### Initializers

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| POST | `/fv-app/v2/initializer/chain` | deadline-chain-definition |  | Import Deadline Chain Definition |
| GET | `/fv-app/v2/initializer/chain/{deadlineChainId}` | export-deadline-chain-definition |  | Exports Deadline Chain Definition |
| GET | `/fv-app/v2/initializer/custom-project-type` | export-custom-project-type-definition |  | Exports Custom Project Type Definition |
| POST | `/fv-app/v2/initializer/custom-project-type` | import-custom-project-type-definition |  | import Custom Project Type Definition |
| GET | `/fv-app/v2/initializer/custom-project-type/custom-section/{customSectionId}` | export-custom-section-definition |  | Export Custom Section Definition |
| GET | `/fv-app/v2/initializer/custom-project-type/{customProjectTypeId}` | export-custom-project-type-definition2 |  | Export Custom Project Type Definition |
| POST | `/fv-app/v2/initializer/custom-project-type/{customProjectTypeId}/custom-section` | import-custom-section-definition |  | Import Custom Section Definition |
| POST | `/fv-app/v2/initializer/saved-report` | import-saved-report-definition |  | Imports Saved Report Definition |
| GET | `/fv-app/v2/initializer/saved-report/{savedReportId}` | export-saved-report-definition |  | Exports Saved Report Definition |

### Mailroom

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Mailroom/Items` | get-mailroom-items |  | Get Mailroom Items |
| POST | `/fv-app/v2/Mailroom/Items/Assign` | assign-mailroom-items |  | Bulk Assign Mailroom Items to a Project |

### Mass Update

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| POST | `/fv-app/v2/Utils/massUpdateDeadlines` | mass-update-for-deadlines |  | Mass Update Deadlines |
| POST | `/fv-app/v2/Utils/massUpdatePhase` | mass-update-for-phase |  | Mass Update Phase |

### Notes

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Notes` | get-note-list |  | Get Note Feed for User |
| POST | `/fv-app/v2/Notes` | create-note |  | Create Note |
| POST | `/fv-app/v2/Notes/move` | move-notes |  | Move Notes to Project |
| DELETE | `/fv-app/v2/Notes/tags/{tagName}` | remove-tag-notes |  | Remove a tag from multiple notes. |
| GET | `/fv-app/v2/Notes/{noteId}` | get-note |  | Get Note |
| PATCH | `/fv-app/v2/Notes/{noteId}` | update-note |  | Update Note |
| POST | `/fv-app/v2/Notes/{noteId}/pin` | pin-note-feed |  | Pin Note to Feed |
| POST | `/fv-app/v2/Notes/{noteId}/unpin` | unpin-note-feed |  | UnPin Note from Feed |
| POST | `/fv-app/v2/projects/{projectId}/notes/{noteId}/pin` | pin-note-project |  | Pin Note to Project |
| POST | `/fv-app/v2/projects/{projectId}/notes/{noteId}/unpin` | unpin-note-project |  | UnPin Note from Project |

### Org Teams

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/projects/{projectId}/team` | get-project-team | 📄 | Get Project Team |
| POST | `/fv-app/v2/projects/{projectId}/team` | add-project-team-member |  | Add Project Team Member |
| POST | `/fv-app/v2/projects/{projectId}/team/users/{userId}/roles` | add-project-team-member-roles |  | [Deprecated] Assign Roles to Member |
| PUT | `/fv-app/v2/projects/{projectId}/team/users/{userId}/roles` | assign-project-team-member-roles |  | Assign Roles to Member |
| GET | `/fv-app/v2/projects/{projectId}/team/{userId}` | get-project-team-member |  | Get Project Team Member |
| PATCH | `/fv-app/v2/projects/{projectId}/team/{userId}` | update-project-team-member |  | Update Project Team Member |
| DELETE | `/fv-app/v2/projects/{projectId}/team/{userId}` | remove-project-team-member |  | Remove Project Team Member |
| GET | `/fv-app/v2/projects/{projectId}/teamorgrolepositions` | get-project-roles-members-with-positions |  | Get Project Team Org Roles with Members and Positions |
| GET | `/fv-app/v2/projects/{projectId}/teamorgroles` | get-project-org-roles | 📄 | Get Project Org Roles |
| GET | `/fv-app/v2/projects/{projectId}/teamroles` | get-project-roles | 📄 | [Deprecated] Get Project Roles |
| GET | `/fv-app/v2/projects/{projectId}/teams` | get-project-teams |  | Get Project Teams |
| PUT | `/fv-app/v2/teamprojects` | assign-teams-to-projects |  | Assign teams to projects. |
| GET | `/fv-app/v2/teams` | get-teams |  | Gets a list of teams. |
| POST | `/fv-app/v2/teams` | create-team |  | Create a team in an org |
| GET | `/fv-app/v2/teams/{teamId}` | get-team-by-id |  | Get details of a team. |
| PUT | `/fv-app/v2/teams/{teamId}/members` | add-team-members |  | Add members to a team |
| POST | `/fv-app/v2/teams/{teamId}/members/remove` | remove-team-members |  | Remove team members from a team. |
| PUT | `/fv-app/v2/teams/{teamId}/members/roles` | assign-team-members-to-roles |  | Assign roles to team members |
| GET | `/fv-app/v2/teams/{teamId}/projects/access` | get-team-projects-access | 📄 | Get a list of projects that the given team has access to |
| PUT | `/fv-app/v2/teams/{teamId}/projects/{projectId}` | add-team-project |  | Adds a team to a project. |
| DELETE | `/fv-app/v2/teams/{teamId}/projects/{projectId}` | remove-team-project |  | Removes a team from a project. |

### Partner Id

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/PartnerIdentifiers/{scope}/{id}` | get-partner-id |  | Get Partner Id |
| PUT | `/fv-app/v2/PartnerIdentifiers/{scope}/{id}` | update-partner-id |  | Update Partner Id |
| DELETE | `/fv-app/v2/PartnerIdentifiers/{scope}/{id}` | delete-partner-id |  | Delete Partner Id |
| GET | `/fv-app/v2/PartnerItemIdentifiers/{scope}/{id}` | V2PartnerIdentity_GetItem |  | Get Partner Id - Collection Item |
| PUT | `/fv-app/v2/PartnerItemIdentifiers/{scope}/{id}` | V2PartnerIdentity_SetItem |  | Update Partner Id - Collection Item |
| DELETE | `/fv-app/v2/PartnerItemIdentifiers/{scope}/{id}` | V2PartnerIdentity_DeleteItem |  | Delete Partner Id - Collection Item |

### Project Activity

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Projects/{projectId}/Notes` | get-project-note-list | 📄 | List project notes |
| GET | `/fv-app/v2/projects/{projectId}/emails` | get-project-email-list | 📄 | Get Project Email List |
| POST | `/fv-app/v2/projects/{projectId}/emails` | add-email-to-project |  | Add an email to a project (JSON body) |
| POST | `/fv-app/v2/projects/{projectId}/encodedEmails` | add-base64-email-to-project |  | Add an email to a project (JSON body) |
| GET | `/fv-app/v2/projects/{projectId}/tasks` | get-project-task-list | 📄 | Get Project Task List |

### Project Contacts

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Projects/{projectId}/contacts` | v2-get-project-vitals | 📄 | Get Project Contact List |
| POST | `/fv-app/v2/Projects/{projectId}/contacts` | add-contact-to-project |  | Add Contacts To Project |
| PATCH | `/fv-app/v2/Projects/{projectId}/contacts/{projectContactId}` | update-project-contact |  | Update Project Contact |
| DELETE | `/fv-app/v2/Projects/{projectId}/contacts/{projectContactId}` | delete-project-contact |  | Delete Project Contact |

### Project Deadline Chains

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| POST | `/fv-app/v2/Projects/{projectId}/DeadlineChains` | create-project-deadline-chain |  | Create project deadline chain |
| PATCH | `/fv-app/v2/projects/{projectId}/chaindates/{chainDateId}/update` | update-chain-date |  | Update chain date |
| GET | `/fv-app/v2/projects/{projectId}/deadlinechains` | get-deadline-chain-list | 📄 | List Deadline Chains for Project |
| GET | `/fv-app/v2/projects/{projectId}/deadlinechains/{deadlineChainId}` | get-deadline-chain |  | Get Deadline Chain |
| PATCH | `/fv-app/v2/projects/{projectId}/deadlinechains/{deadlineChainId}` | update-deadline-chain |  | Update Deadline Chain |
| DELETE | `/fv-app/v2/projects/{projectId}/deadlinechains/{deadlineChainId}` | delete-deadline-chain |  | Delete Deadline Chain |

### Project Deadlines

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/projects/{projectId}/deadlines` | get-project-deadline-list | 📄 | Get Project Deadline List |
| POST | `/fv-app/v2/projects/{projectId}/deadlines` | create-project-deadline |  | Create a project deadline |
| GET | `/fv-app/v2/projects/{projectId}/deadlines/{deadlineId}` | get-project-deadline |  | Get Project Deadline |
| PATCH | `/fv-app/v2/projects/{projectId}/deadlines/{deadlineId}` | update-project-deadline |  | Update Project Deadline |
| DELETE | `/fv-app/v2/projects/{projectId}/deadlines/{deadlineId}` | delete-project-deadline |  | Delete Project Deadline |

### Project Types

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/ProjectTypes` | get-project-type-list | 📄 | Get Project Type List |
| POST | `/fv-app/v2/ProjectTypes` | create-project-type |  | [Beta] Create Project Type |
| GET | `/fv-app/v2/ProjectTypes/{projectTypeId}` | get-project-type |  | Get Project Type |
| PUT | `/fv-app/v2/ProjectTypes/{projectTypeId}` | update-project-type |  | [Beta] Update Project Type |
| DELETE | `/fv-app/v2/ProjectTypes/{projectTypeId}` | remove-project-type |  | [Beta] Remove Project Type |
| GET | `/fv-app/v2/ProjectTypes/{projectTypeId}/phases` | get-project-type-phase-list | 📄 | Get Project Type Phase List |

### Projects

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Projects` | get-project-list | 📄 | Get Project List |
| POST | `/fv-app/v2/Projects` | create-project |  | Create Project |
| DELETE | `/fv-app/v2/Projects/tags/{tagName}` | remove-tag-projects |  | Remove a tag from multiple projects. |
| GET | `/fv-app/v2/Projects/{projectId}` | get-project |  | Get Project |
| PATCH | `/fv-app/v2/Projects/{projectId}` | update-project |  | Update Project |
| GET | `/fv-app/v2/Projects/{projectId}/Vitals` | v2-get-project-vitals2 |  | Get Project Vitals |
| POST | `/fv-app/v2/Utils/conflictcheck/projects/{projectId}` | search-project-conflicts |  | Search project for conflicts |
| POST | `/fv-app/v2/hashtags/{hashtag}` | create-hashtag |  | Add Hashtag To Projects |
| PUT | `/fv-app/v2/projects/bulk` | bulk-update-projects-clients |  | Bulk update project clients |
| POST | `/fv-app/v2/projects/{projectId}/guestusers` | add-project-guest-user |  | Create Project Guest User |
| DELETE | `/fv-app/v2/projects/{projectid}` | archive-project |  | Archive Project |
| POST | `/fv-app/v2/projects/{projectid}/sectionvisibility` | toggle-section-visibility |  | Toggle Section Visibility |

### Reports

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Reports` | get-saved-reports-list | 📄 | Get Saved Reports List |
| GET | `/fv-app/v2/Reports/{reportid}` | get-saved-report | 📄 | Run Saved Report |

### Share Links

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/ShareLinks` | get-sharelinks-by-orgid |  | Get page of share links |
| POST | `/fv-app/v2/ShareLinks/DeleteBatch` | delete-sharelinks-by-linkkey |  | Delete batch of share links |
| GET | `/fv-app/v2/ShareLinks/{linkKey}` | get-sharelink-by-linkkey |  | Get share link |
| DELETE | `/fv-app/v2/ShareLinks/{linkKey}` | delete-sharelink-by-linkkey |  | Delete share link |

### Task

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| POST | `/fv-app/v2/projects/{projectId}/tasks/{taskId}/pin` | pin-task-project |  | Pin Task to Project |
| POST | `/fv-app/v2/projects/{projectId}/tasks/{taskId}/unpin` | unpin-task-project |  | UnPin Task from Project |
| GET | `/fv-app/v2/tasks` | get-task-list |  | Get Tasks for User |
| POST | `/fv-app/v2/tasks` | create-task |  | Create Task |
| POST | `/fv-app/v2/tasks/{taskID}/complete` | complete-task |  | Complete Task |
| POST | `/fv-app/v2/tasks/{taskID}/uncomplete` | uncomplete-task |  | Uncomplete Task |
| GET | `/fv-app/v2/tasks/{taskId}` | get-task |  | Get Task |
| PATCH | `/fv-app/v2/tasks/{taskId}` | update-task |  | Update Task Body |
| DELETE | `/fv-app/v2/tasks/{taskId}` | unassign-task |  | Unassign Task |
| PATCH | `/fv-app/v2/tasks/{taskId}/assign/{assigneeID}` | assign-task |  | Assign Task |
| POST | `/fv-app/v2/tasks/{taskId}/pin` | pin-task-feed |  | Pin Task to Feed |
| PUT | `/fv-app/v2/tasks/{taskId}/snooze` | snooze-task |  | Change Task Due Date (Snooze) |
| POST | `/fv-app/v2/tasks/{taskId}/unpin` | unpin-task-feed |  | UnPin Task from Feed |

### Users

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/Users` | V2Users_Get | 📄 | Get User List |
| GET | `/fv-app/v2/Users/Me` | get-current-user |  | Get Service Account/API User |
| GET | `/fv-app/v2/users/{userId}` | get-user |  | Get User |
| DELETE | `/fv-app/v2/users/{userId}` | V2Users_Delete |  | Remove User |
| GET | `/fv-app/v2/users/{userId}/appointments` | get-users-calendar-items | 📄 | Get User's Calendar Items |
| GET | `/fv-app/v2/users/{userId}/projects/access` | get-user-projects-access | 📄 | Gets a list of projects that the given user has access to |
| GET | `/fv-app/v2/users/{userId}/recentprojects` | get-users-recent-projects |  | Get User's Recent Projects |
| GET | `/fv-app/v2/users/{userId}/tasks` | get-users-task-list | 📄 | Get User's Task List |
| POST | `/fv-app/v2/utils/GetUserOrgsWithToken` | get-user-orgs-with-token |  | Get User Orgs With Token |

### Vitals

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/vitals` | get-vitals |  | Get Project Vitals |

### Webhooks

| Method | Path | Operation | Pg | Summary |
|--------|------|-----------|----|---------|
| GET | `/fv-app/v2/webhooks/Events` | get-webhook-events |  | Get Available Webhook Events |
| POST | `/fv-app/v2/webhooks/subscription` | create-webhook-subscription |  | Create Webhook Subscription |
| GET | `/fv-app/v2/webhooks/subscription/{subscriptionId}` | get-webhook-subscription |  | Get Webhook Subscription By Id |
| PUT | `/fv-app/v2/webhooks/subscription/{subscriptionId}` | update-webhook-subscription |  | Update Webhook Subscription |
| DELETE | `/fv-app/v2/webhooks/subscription/{subscriptionId}` | delete-webhook-subscription |  | Delete Webhook Subscription |
| GET | `/fv-app/v2/webhooks/subscriptions` | get-webhook-subscriptions |  | Get Webhook Subscriptions |

## Webhook event enums

Webhook subscriptions are defined by **object × type**: 28 objects × 27 event types.

**Event objects (28):** `Appointment`, `Chain_Deadline`, `Collection_Item`, `Comment`, `Contact`, `Deadline`, `Document`, `Email`, `Fax`, `Folder`, `Form`, `Invoice`, `Note`, `Org_Member`, `Payment`, `Project`, `ProjectFunds`, `Section`, `Sms`, `Taskflow`, `Roles`, `Analysis_Job`, `Teams`, `Mass_Update`, `Project_Billing_Settings`, `Org_Billing_Settings`, `Org_Team_Member`, `Project_Member`

**Event types (27):** `Created`, `Deleted`, `Updated`, `Generated`, `Related`, `Unrelated`, `Reverted`, `Versioned`, `Sent`, `Received`, `Assigned`, `Unassigned`, `Completed`, `Uncompleted`, `PhaseChanged`, `Toggle`, `Executed`, `Reset`, `Queued`, `Added`, `Removed`, `Started`, `Failed`, `Merged`, `Broken`, `Undeleted`, `Archived`

Subscription endpoints: `GET/POST /fv-app/v2/webhooks/subscription[s]`, `GET/PUT/DELETE /fv-app/v2/webhooks/subscription/{subscriptionId}`, `GET /fv-app/v2/webhooks/Events`.

## Identity API (token minting)

- Host `https://identity.filevine.com` — OpenAPI 3.0.1 "Filevine Identity API".
- **POST /connect/token** — Exchange Token
    - body (`application/x-www-form-urlencoded`): `client_id`, `client_secret`, `grant_type`, `scope`, `token`
- **POST /identity/user** — Create User Invite
