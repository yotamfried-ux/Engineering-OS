# SAM 3 / 3.1 for video segmentation and sports tracking

Canonical upstream: https://github.com/facebookresearch/sam3
Meta documentation: https://ai.meta.com/sam3/ ; https://ai.meta.com/blog/segment-anything-model-3/
Status: RESEARCH REFERENCE / NOT INSTALLED OR BENCHMARKED.

SAM 3 detects, segments and tracks text/visual-prompted concepts in images/video. SAM 3.1 offers object multiplexing for more efficient multi-object tracking. The upstream README documents CUDA/PyTorch requirements, checkpoint access, and a SAM-specific license (do **not** assume MIT or unconditional commercial use). Verify license and hardware before adoption.

Use cases: segment surfers and boards, track objects, bootstrap annotation and QA. **Not** a turnkey referee: segmentation does not establish sports rules, shot accuracy, identity continuity under occlusion, biomechanics or validated performance metrics. Compare on representative videos against human-approved ground truth using identity switches, segmentation accuracy, tracking continuity, latency, memory and cost. Require consent/privacy safeguards for identifiable people and employment surveillance; never treat a tracking demo as justification for workplace monitoring.
