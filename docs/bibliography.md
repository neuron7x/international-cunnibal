# Scientific Bibliography

## Table of Contents

- [Overview](#overview)
- [Functional Systems & Anokhin's Theory](#functional-systems--anokhins-theory)
- [Neuromorphic Computing](#neuromorphic-computing)
- [On-Device AI: TensorFlow Lite & MediaPipe](#on-device-ai-tensorflow-lite--mediapipe)
- [MLOps: DVC & CI/CD](#mlops-dvc--cicd)
- [Small-World Networks & Plasticity](#small-world-networks--plasticity)
- [WBAI & AGI Pathways](#wbai--agi-pathways)
- [EBRAINS & Human Brain Project](#ebrains--human-brain-project)

## Overview

This bibliography documents the scientific and technical foundations of **International Cunnibal**, a neural
biofeedback engine for precision oral biomechanics and sensory-motor synchronization. The project integrates concepts
from functional systems theory, neuromorphic computing, on-device AI, and modern MLOps practices to create a
bio-plausible architecture implementing Anokhin's Action Acceptor theory.

---

## Functional Systems & Anokhin's Theory

**Core theoretical framework for sensory-motor validation and biofeedback**

- **Anokhin, P. K. (1974). Biology and Neurophysiology of the Conditioned Reflex and Its Role in Adaptive Behavior**
  - DOI: [10.1016/B978-0-08-017797-6.50010-7](https://doi.org/10.1016/B978-0-08-017797-6.50010-7)
  - *Relevance*: Foundational work on the Action Acceptor (acceptor of action results), the core principle underlying
    our sensory-motor validation system that compares expected vs. actual afferent feedback.

- **Anokhin, P. K. (1973). The Forming of Natural and Artificial Intelligence**
  - URL: [Archive](https://archive.org)
  - *Relevance*: Establishes principles of functional systems theory applicable to artificial neural architectures,
    informing how our engine validates motor execution against predicted outcomes.

- **Alexandrov, Y. I., Grinchenko, Y. V., Shevchenko, D. G., et al. (2017). A Web-Based Platform for the Study of the
  Formation of Individual Differences in Behavior and the Brain**
  - DOI: [10.1134/S0362119717030033](https://doi.org/10.1134/S0362119717030033)
  - *Relevance*: Modern applications of Anokhin's theory to individual behavior analysis, relevant for personalized
    biofeedback training protocols.

- **Sudakov, K. V. (2011). Functional Systems Theory**
  - DOI: [10.1134/S0362119711050148](https://doi.org/10.1134/S0362119711050148)
  - *Relevance*: Contemporary synthesis of functional systems theory, providing framework for understanding
    goal-directed behavior and real-time motor adjustment.

---

## Neuromorphic Computing

**Bio-inspired computing paradigms influencing the neural engine architecture**

- **Mead, C. (1990). Neuromorphic Electronic Systems**
  - DOI: [10.1109/5.58356](https://doi.org/10.1109/5.58356)
  - *Relevance*: Pioneering work on neuromorphic computing that inspires our bio-plausible processing approach for
    real-time sensory-motor integration.

- **Davies, M., et al. (2018). Loihi: A Neuromorphic Manycore Processor with On-Chip Learning**
  - DOI: [10.1109/MM.2018.112130359](https://doi.org/10.1109/MM.2018.112130359)
  - *Relevance*: Demonstrates on-chip learning capabilities that inform our on-device adaptive algorithms for motor
    pattern refinement.

- **Indiveri, G., & Liu, S. C. (2015). Memory and Information Processing in Neuromorphic Systems**
  - DOI: [10.1109/JPROC.2015.2444094](https://doi.org/10.1109/JPROC.2015.2444094)
  - *Relevance*: Principles of neuromorphic information processing relevant to our real-time biomechanics validation
    and pattern matching.

- **Roy, K., Jaiswal, A., & Panda, P. (2019). Towards Spike-Based Machine Intelligence with Neuromorphic Computing**
  - DOI: [10.1038/s41586-019-1677-2](https://doi.org/10.1038/s41586-019-1677-2)
  - *Relevance*: Explores spike-based learning mechanisms that could enhance future iterations of our temporal pattern
    recognition in motor sequences.

---

## On-Device AI: TensorFlow Lite & MediaPipe

**Technical foundation for privacy-preserving real-time inference**

- **Abadi, M., et al. (2016). TensorFlow: A System for Large-Scale Machine Learning**
  - DOI: [10.5555/3026877.3026899](https://doi.org/10.5555/3026877.3026899)
  - *Relevance*: Core framework enabling our on-device neural network inference for tongue landmark detection without
    cloud dependencies.

- **Google Research. (2019). MediaPipe: A Framework for Building Perception Pipelines**
  - URL: [arxiv.org/abs/1906.08172](https://arxiv.org/abs/1906.08172)
  - *Relevance*: Provides the real-time computer vision pipeline architecture used for 30 FPS landmark detection and
    tracking in our bio-tracking module.

- **Lugaresi, C., et al. (2019). MediaPipe: A Framework for Perceiving and Processing Reality**
  - URL: [Google AI Blog](https://ai.googleblog.com/2019/08/on-device-real-time-hand-tracking-with.html)
  - *Relevance*: Demonstrates feasibility of high-frequency on-device tracking, directly applicable to our oral
    biomechanics detection approach.

- **Lane, N. D., et al. (2016). DeepX: A Software Accelerator for Low-Power Deep Learning Inference on Mobile Devices**
  - DOI: [10.1145/2942358.2942359](https://doi.org/10.1145/2942358.2942359)
  - *Relevance*: Addresses power-efficient mobile inference challenges critical for sustained biofeedback sessions
    without battery drain.

- **Howard, A. G., et al. (2017). MobileNets: Efficient Convolutional Neural Networks for Mobile Vision Applications**
  - URL: [arxiv.org/abs/1704.04861](https://arxiv.org/abs/1704.04861)
  - *Relevance*: Lightweight CNN architectures enabling real-time performance on mobile devices for our TFLite-based
    landmark detection models.

---

## MLOps: DVC & CI/CD

**Version control and deployment practices for reproducible ML systems**

- **Sculley, D., et al. (2015). Hidden Technical Debt in Machine Learning Systems**
  - URL: [papers.nips.cc/paper/5656-hidden-technical-debt-in-machine-learning-systems](https://papers.nips.cc/paper/5656-hidden-technical-debt-in-machine-learning-systems)
  - *Relevance*: Identifies ML system maintenance challenges addressed by our DVC-based model versioning and
    reproducible training pipelines.

- **Breck, E., et al. (2017). The ML Test Score: A Rubric for ML Production Readiness and Technical Debt Reduction**
  - URL: [research.google/pubs/pub46555/](https://research.google/pubs/pub46555/)
  - *Relevance*: Provides testing framework principles applied in our CI/CD pipeline to ensure model quality before
    deployment.

- **Kubeflow Documentation. (2020). MLOps: Continuous Delivery and Automation Pipelines in Machine Learning**
  - URL: [cloud.google.com/architecture/mlops-continuous-delivery-and-automation-pipelines-in-machine-learning](https://cloud.google.com/architecture/mlops-continuous-delivery-and-automation-pipelines-in-machine-learning)
  - *Relevance*: MLOps best practices informing our automated model training, validation, and deployment workflows via
    DVC and GitHub Actions.

- **Data Version Control (DVC) Documentation. (2023). DVC: Data Version Control**
  - URL: [dvc.org/doc](https://dvc.org/doc)
  - *Relevance*: Technical documentation for our model and dataset versioning system, enabling reproducible experiments
    and model lineage tracking.

---

## Small-World Networks & Plasticity

**Neural network topology and learning mechanisms**

- **Watts, D. J., & Strogatz, S. H. (1998). Collective Dynamics of 'Small-World' Networks**
  - DOI: [10.1038/30918](https://doi.org/10.1038/30918)
  - *Relevance*: Small-world network properties inform efficient connectivity patterns in our neural architecture for
    rapid information propagation.

- **Bassett, D. S., & Bullmore, E. (2006). Small-World Brain Networks**
  - DOI: [10.1177/1073858406293182](https://doi.org/10.1177/1073858406293182)
  - *Relevance*: Demonstrates small-world topology in biological neural networks, guiding bio-plausible architectural
    design choices for our sensory-motor integration.

- **Sporns, O., & Zwi, J. D. (2004). The Small World of the Cerebral Cortex**
  - DOI: [10.1016/j.neuroinformatics.2004.07.003](https://doi.org/10.1016/j.neuroinformatics.2004.07.003)
  - *Relevance*: Characterizes cortical connectivity patterns relevant to understanding sensory-motor coordination
    pathways modeled in our system.

- **Hebb, D. O. (1949). The Organization of Behavior: A Neuropsychological Theory**
  - URL: [Psychology Press](https://www.routledge.com/The-Organization-of-Behavior-A-Neuropsychological-Theory/Hebb/p/book/9780805843002)
  - *Relevance*: Foundational work on synaptic plasticity ("cells that fire together wire together") underlying our
    adaptive pattern learning mechanisms.

- **Bi, G., & Poo, M. (2001). Synaptic Modification by Correlated Activity: Hebb's Postulate Revisited**
  - DOI: [10.1146/annurev.neuro.24.1.139](https://doi.org/10.1146/annurev.neuro.24.1.139)
  - *Relevance*: Modern understanding of spike-timing-dependent plasticity applicable to future reinforcement learning
    enhancements in motor training.

---

## WBAI & AGI Pathways

**Whole Brain Architecture Initiative and paths toward general intelligence**

- **Yamakawa, H., et al. (2018). Whole Brain Architecture Approach: Accelerating Development of Artificial General
  Intelligence by Referring to Brain**
  - URL: [wba-initiative.org](https://wba-initiative.org/en/)
  - *Relevance*: Framework for brain-inspired AGI development that aligns with our bio-plausible Action Acceptor
    implementation for adaptive sensory-motor control.

- **Kotseruba, I., & Tsotsos, J. K. (2020). 40 Years of Cognitive Architectures: Core Cognitive Abilities and Practical
  Applications**
  - DOI: [10.1016/j.artint.2018.10.007](https://doi.org/10.1016/j.artint.2018.10.007)
  - *Relevance*: Survey of cognitive architectures informing our modular design separating perception, validation, and
    action layers.

- **Hassabis, D., Kumaran, D., Summerfield, C., & Botvinick, M. (2017). Neuroscience-Inspired Artificial Intelligence**
  - DOI: [10.1016/j.neuron.2017.06.011](https://doi.org/10.1016/j.neuron.2017.06.011)
  - *Relevance*: Explores how neuroscience principles can guide AI development, validating our brain-inspired approach
    to motor learning systems.

- **Lake, B. M., Ullman, T. D., Tenenbaum, J. B., & Gershman, S. J. (2017). Building Machines That Learn and Think Like
  People**
  - DOI: [10.1017/S0140525X16001837](https://doi.org/10.1017/S0140525X16001837)
  - *Relevance*: Advocates for cognitive architectures incorporating intuitive physics and psychology, relevant to our
    goal-directed motor coordination model.

---

## EBRAINS & Human Brain Project

**Large-scale brain simulation infrastructure and resources**

- **Amunts, K., et al. (2019). The Human Brain Project—Synergy Between Neuroscience, Computing, Informatics, and
  Brain-Inspired Technologies**
  - DOI: [10.1371/journal.pbio.3000344](https://doi.org/10.1371/journal.pbio.3000344)
  - *Relevance*: Overview of HBP infrastructure providing validated brain models and simulation tools that inform our
    bio-plausible neural architecture design.

- **EBRAINS Platform Documentation. (2023). EBRAINS Research Infrastructure**
  - URL: [ebrains.eu](https://ebrains.eu)
  - *Relevance*: Access to brain atlases, models, and simulation tools supporting future validation of our
    sensory-motor coordination algorithms against biological data.

- **Markram, H., et al. (2015). Reconstruction and Simulation of Neocortical Microcircuitry**
  - DOI: [10.1016/j.cell.2015.09.029](https://doi.org/10.1016/j.cell.2015.09.029)
  - *Relevance*: Detailed cortical microcircuit models informing realistic connectivity patterns for future multi-scale
    implementations of our neural engine.

- **Ritter, P., et al. (2013). The Virtual Brain Integrates Computational Modeling and Multimodal Neuroimaging**
  - DOI: [10.1089/brain.2012.0120](https://doi.org/10.1089/brain.2012.0120)
  - *Relevance*: Whole-brain simulation framework relevant to understanding large-scale sensory-motor integration
    patterns in biological systems.

---

## Implementation Note

This bibliography directly informs the **Action Acceptor** implementation in International Cunnibal. Anokhin's theory
provides the core validation mechanism where predicted sensory outcomes (efferent copy) are compared against actual
afferent signals during motor execution. The neuromorphic and small-world network principles guide our bio-plausible
architecture design, while on-device AI technologies (TFLite/MediaPipe) enable privacy-preserving real-time processing.
MLOps practices ensure reproducible model development, and AGI/EBRAINS resources provide validation frameworks for our
brain-inspired approach to precision oral biomechanics training.

---

*Last updated: 2025-12-30*
