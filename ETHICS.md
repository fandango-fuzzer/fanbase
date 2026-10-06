# Ethical Considerations

We structure the discussion of ethical considerations by linking our stakeholder analysis to the impacts generated during research and the long-term impacts of our work. We conclude with the justification for conducting this research.

## Stakeholders

Our work involves four stakeholder groups:

1. _developers_ of software systems;
2. _end users_ of software systems;
3. well-intentioned _security researchers_; and
4. _malicious actors_.

## Impact of the Research

We see both positive and negative impacts of our work, affecting the stakeholders.

* Our work enables _developers_ and _well-intentioned security researchers_ to easily identify and fix bugs and vulnerabilities in software systems, leading to more secure and reliable software for end users. By open-sourcing our tools and techniques, we empower the community to use and extend our techniques to further assess, audit, and improve the overall security of software systems.
* Our work also enables _malicious actors_ to identify and exploit bugs and vulnerabilities in software systems. This can lead to denial of service attacks, security breaches, data theft, and other malicious activities that can harm end users.


## Mitigations during Research

During this research, we have taken a number of measures to mitigate potential harms.

* We have followed standard practices for _responsible disclosure_ by notifying the affected parties of any vulnerabilities discovered during our experiments before any public release of the findings, ensuring that the software vendors have the opportunity to address the vulnerabilities before they are exposed to the public. These measures protect developers and end users.
* We only publish _abstract descriptions_ of file formats and vulnerabilities, without providing concrete inputs that could be used to exploit the vulnerabilities. Concrete bug-triggering inputs are released to third parties only after the respective bug has been confirmed to be fixed. These measures protect developers and end users.
* We have sought _ethical review and approval_ from our institution's ethics board to ensure that our research adheres to ethical standards and guidelines, particularly in relation to data handling and potential impacts on stakeholders. This measure protects all stakeholder groups.
* We have been _transparent_ about our research methods, findings, and potential impacts, allowing stakeholders to make informed decisions about how to use or respond to our work. This measure protects developers and well-intentioned security researchers.
* We will release our research artifacts, notably the file specifications, in _small portions over time_ to allow developers and security researchers to address potential vulnerabilities in a timely manner. This measure protects developers and end users.

Our work does not involve any experiments on human subjects, use of personal data, or other activities that could raise significant ethical concerns.


## Mitigations of Long-Term Impact

Our work allows testing and fuzzing systems easily that have never been subject to automated test generation before, especially as it does not require access to the code of the systems under test. This includes systems that are used in critical infrastructure, such as industrial control systems, medical devices, transportation systems, as well as business or administration software. We expect a significant burden for their developers and maintainers to triage and address the vulnerabilities discovered.

Still, we expect the long-term impact of our work to be _positive_, as it contributes to the overall security and reliability of software systems, benefiting developers, end users, and the broader security community. While our research also enables malicious actors to detect bugs and vulnerabilities, the alternative of "security by obscurity" (i.e., _not_ searching for vulnerabilities because there might be some) is widely recognized as ineffective.

A policy of total transparency means that we cannot control who will use our work and how. To resolve this _dual-use_ dilemma, our fundamental assumption is that more well-intentioned developers and security researchers will use our work to improve security and reliability more than few malicious actors will use it to cause harm.

## Decision to Conduct the Research

This work can be applied to all software systems that accept some kind of input - in other words, all software systems. By systematically producing inputs for testing implementations, we contribute to positive impacts for end users, developers, and the broader security community as listed above.
