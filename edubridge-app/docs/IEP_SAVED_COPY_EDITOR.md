# Saved IEP draft copy editor

Only open plans with nonempty draft versions expose a temporary-copy action.
The history is reloaded and its captured baseline compared before navigation.
Changed, missing, inaccessible, closed or submitted sources do not open.

The editor prefills title, evaluation, dates, summary, ordered goals and
accommodations. Existing field validation, preview and discard handling remain.
Source replacement resets the editor through its key. The saved plan is never
mutated by this UI. It explicitly describes a temporary copy and hides the
create-save action so editing cannot accidentally create a second plan.

Updating the original draft remains unfinished. It requires a server-issued
revision token, authoritative edit permission, atomic expected-revision update,
a conflict response, and a validated updated-version receipt. A client-side
baseline comparison cannot replace that transaction. No backend is changed here.

The update-contract batch adds a separate save-review screen. Create-save is
never used for an existing version. The proposed update capability must load
before saving becomes enabled; see IEP_DRAFT_UPDATE_CONTRACT.md.
