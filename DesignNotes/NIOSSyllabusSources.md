# NIOS syllabus catalogue

Research checked: 17 November 2026. This is a bundled, offline course catalogue, not an AI-generated or live-synced syllabus. `Homeschool/Core/Resources/NIOSSyllabus.json` contains the source URLs, editions, stable identities and coverage notes. `MockData.syllabus(for:)` returns the current child's selected subjects, including locked core subjects, through `NIOSSyllabus`.

## Level mapping

| App choice | NIOS programme | School equivalence |
| --- | --- | --- |
| Level A | Open Basic Education A | Classes 1–3; equivalent to Class 3 |
| Level B | Open Basic Education B | Classes 4–5; equivalent to Class 5 |
| Level C | Open Basic Education C | Classes 6–8; equivalent to Class 8 |
| Grade 10 | Secondary | Class 10 |
| Grade 12 | Senior Secondary | Class 12 |

NIOS does not publish a separate OBE course for every individual school grade. Do not invent Class 1, 2, 4, 6, or 7 book lists from these equivalence levels. Blank or unknown levels return no syllabus; they do not silently default to Level C.

## Primary sources and interpretation

- [NIOS OBE programme and equivalence](https://sdmis.nios.ac.in/modules/obe-registration/obe).
- [NIOS children's prospectus 2026–27](https://nios.ac.in/media/documents/prospectus/OBE_Prospectus/OBE_Porspectus_Children_2026-27_Final.pdf), section 3.1: accredited agencies may use NIOS, State Board or other national-board textbooks; families must confirm their own centre's material. A single mandatory children's textbook sequence cannot be claimed.
- [NIOS official OBE materials](https://nios.ac.in/departmentsunits/academic/open-basic-education-(obe)/obesimen.aspx).
- NIOS OBE exemplar curricula: [A](https://cdn.nios.ac.in/cms/documents/2020/Apr/01/m754PG4PgpukKLCKLUJw.pdf), [B](https://cdn.nios.ac.in/cms/documents/2020/Apr/01/5XGOVETKNhB75cII863x.pdf), [C](https://cdn.nios.ac.in/cms/documents/2020/Apr/01/1pWs6XuXuIItLWI3QGvh.pdf). These are explicitly used in adult education. The app labels them **exemplar outlines**, never a universal children's syllabus. Topic labels summarise the published course descriptions; lesson numbering, including the gap before Science C lesson 19, is preserved.
- Hindi model competencies: [A](https://nios.ac.in/media/documents/ENGAlevel.pdf), [B](https://nios.ac.in/media/documents/EngBlevel.pdf), [C](https://nios.ac.in/media/documents/engClevel.pdf). These use learning areas rather than invented textbook chapter names. Reading selections remain agency-specific.
- [NIOS My Book of English, OBE C](https://nios.ac.in/media/documents/OBE_SLM/OBEEnglish_LevelC.pdf): 25 actual lessons. Reading, speaking, writing and comprehension rows are included only where those activity headings occur in each lesson. Links open the relevant PDF page.
- [NIOS Secondary material index](https://nios.ac.in/online-course-material/secondary-courses.aspx) and its subject pages.
- [NIOS Senior Secondary material index](https://nios.ac.in/online-course-material/sr-secondary-courses.aspx) and its subject pages.
- [Revised Senior Secondary English 302](https://nios.ac.in/online-course-material/sr-secondary-courses/english-(302)-new.aspx), introduced for 2025–26. [NIOS transition notice](https://cdn.nios.ac.in/cms/documents/2026/Apr/23/1776926473_302-Syllabus_regarding.pdf). The old and new English outlines are not mixed.

## Coverage

The catalogue covers the app's subject choices at all five supported levels. Records use three explicit coverage states:

- `lessons`: official chapter/lesson index; detailed topic headings where verified from the textbook. Otherwise that chapter remains one trackable lesson, rather than invented subtopics.
- `outline`: published model/exemplar or competency outline. A parent can plan its topics explicitly. It is not automatically imposed as the child's textbook sequence.
- `sourceOnly`: chapter outline not verified. An official index or material archive is linked, with no invented chapters or completion percentage.

Some regional-language materials are supplied by NIOS as archives rather than chapter indexes. Several OBE language and vocational choices also lack a verified outline in this catalogue. They remain source-only. This implementation does **not** claim complete chapter coverage for every elective. Some choices currently offered by the app still require the family's accredited agency to confirm availability and learning material.

Source-only choices include OBE English A/B, Sanskrit, Urdu, regional language, several pre-vocational skills; Secondary regional languages and some vocational certificates; Senior Secondary Tamil and Punjabi. See each bundled record for its precise status and source.

Optional modules found in official indexes are labelled and excluded from automatic scheduling. Available-topic counts are learning records, not an examination eligibility or marks calculation. The catalogue is not an exam-only syllabus bifurcation or a substitute for practical/TMA requirements.

Corrected Secondary subject codes: Kannada **208**, Sanskrit **209**, Punjabi **210**, Assamese **228**, Malayalam **232**, Odia **233**. Existing selections are keyed by subject name, so these corrections do not discard the parent's subject choices.

## Tracking and planning rules

- `WeekActivity.syllabusTopicID` is optional so old persisted plans decode unchanged. New repeated occurrences preserve the topic link but have their own activity IDs and completion state.
- Completed: at least one explicitly linked activity is complete in this child's saved current or archived plans.
- This week: an incomplete linked activity is scheduled Monday inclusive through the next Monday exclusive. Completed takes precedence. Future and overdue tasks are not labelled as planned this week.
- Not started: neither condition applies. Subject totals, generic task names and unrelated completions never mark topics complete.
- Active occurrences take precedence over duplicate archived copies. Topic identities include programme level and source edition identity.
- Parents can plan a topic with the existing activity editor, or explicitly link an existing activity. Unlinking preserves its original completion and credited minutes. Toggling completion changes the same saved learning activity used by Home and Progress.
- Existing weeks and completed activities are preserved. New weeks use verified non-optional lesson topics in order, skipping already completed topic IDs. Exemplar-only courses retain the app's existing activity suggestions until parents explicitly plan from the outline.
- Editing a linked activity's title or subject clears the association. Timing, duration and note edits retain it. Parent-edited tasks are protected from automatic regeneration.

## Maintenance and verification

Only metadata, headings and short topic labels are bundled, not downloaded textbooks. Review the official sources before refreshing the catalogue. Preserve topic identities across editorial changes; migrate saved activity links before removing or replacing existing identities.

Verification covers catalogue decoding and unique identities, official source hosts, every supported level, mandatory and selected-subject filtering, corrected language codes, revised English, week boundaries, historical completion, duplicate activity precedence, child isolation, old-save decoding, repeated activities, sequential new-week planning and preserving the existing saved week. Xcode builds and simulator navigation are checked separately.
