# Jabalia teacher personnel-document metadata minimization

## Security change

Institution-authorized teacher document listing previously returned raw private storage_path, original_filename, mime_type and file_size from jabalia_teacher_documents to the React web client. The browser does not need those confidential low-level file identifiers to show attachment status.

The listing and newly created document responses now use an explicit allowed-field projection and return has_file (0/1) instead of sensitive file path/name/media-size metadata. IDs, type, title, issuance dates and safe existing document descriptions remain restricted to already-authorized Jabalia institution admins.

The React institution teacher document panel now uses has_file to enable download, forbid overwriting/deleting attached signed contracts and display missing attachments. It never renders original personnel filenames. The existing authenticated download action remains audited and is delivered through the same private Laravel endpoint with Cache-Control: private, no-store. Generic downloaded filenames use the Blob response media type for PDF/JPEG/PNG/WebP, or .bin fallback.

## Scope / constraints

- No public document links, no new school-director/deputy/teacher access rights, and no change to underlying file paths, existing confidential backups or document retention.
- This reduces accidental exposure of private storage structure in browser state, developer tools and API logs. It does not constitute a penetration test, encryption audit or legally accepted personnel-file policy.
- The has_file flag indicates a path is attached in metadata, **not** a verified file, signed document or authorization to open a contract. The authorized download endpoint separately validates file existence.
- Existing institution-user scope, per-document teacher/school/organization guards and access audit remain required. Failure of audit storage continues to fail closed for downloads.
- Signed teacher contract periods from PR #1380 remain a separate registry and do not require returning raw file paths to the browser.

## Testing

- Laravel tests verify listed and newly created document JSON never contains private filenames or storage paths and listings remain audited and scoped.
- React regression prevents returning to item.storage_path and item.original_filename and verifies generic MIME-based download naming.
- No migration. Protected CI, isolated Jabalia deployment and role-based UAT are still required. Signed institution acceptance and private backup recovery are not asserted.

Tracking: issue #1364.
