/// Server-authoritative workflow state for a healthcare case.
enum CaseStatus {
  submitted,
  inReview,
  underDiscussion,
  answered,
  rejected,
  closed,
}
