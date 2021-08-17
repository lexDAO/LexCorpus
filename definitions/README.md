# Legal Engineering Definitions
> Built from [OS Law](https://github.com/LeXpunK-Army/Open-Source-Law) and [SCoDA](https://github.com/lex-node/SCoDA-Simple-Code-Deference-Agreement-), License: [CC-BY-SA-4.0](https://github.com/lex-node/SCoDA-Simple-Code-Deference-Agreement-/blob/master/LICENSE.md), Copyright - Gabriel Shapiro

***“Account Address”*** means a public key address on the Designated Blockchain Network that is uniquely associated with a single private key, and at which no smart contract has been deployed.

***“Confirmation”*** of a transaction shall be deemed to have occurred if and only if such transaction has been recorded in accordance with the Consensus Rules in a valid block whose hashed header is referenced by at least [ten] subsequent valid blocks on the Designated Blockchain.

***“Consensus Attack”*** means an attack that: (i) is undertaken by or on behalf of a block producer who controls, or group of cooperating block producers who collectively control, a preponderance of the means of block production on the Designated Blockchain Network; and (ii) has the actual or intended effect of: (A) reversing any transaction made to or by the Designated Smart Contract after Confirmation of such transaction, including any “double spend” attack having or intended to have such effect; or (B) preventing inclusion in blocks or Confirmation of any transaction made to or by the Designated Smart Contract, including any “censorship attack,” “transaction withholding attack” or “block withholding attack” having or intended to have such effect.

***“Consensus Rules”*** means the rules for transaction validity, block validity and determination of the canonical blockchain that are embodied in the Designated Client.

***"Decentralized Organization"***: The term "decentralized organization" means a cloud cooperative with an enumerated mission, purpose or mandate, and having fluid affiliation or membership through participation.

* See explainer article [here](https://sh-brennan.medium.com/decentralized-organizations-another-round-of-definitional-questions-existential-crises-2ee6a93f82b5) for background and approach.

***“Designated Blockchain”*** means at any give time, the version of the digital blockchain ledger commonly known as “[Ethereum]” that at least a majority of nodes running the Designated Client recognize as canonical as of such time. For the avoidance of doubt, the “Designated Blockchain” does not refer to the digital blockchain ledger commonly known as “Ethereum Classic” or any other blockchain ledgers from which or to which the Designated Blockchain has been “forked” or “split”.

***“Designated Blockchain Network”*** means the Ethereum mainnet (networkID:1, chainID:1), as recognized by the Designated Client.

***“Designated Client”*** means the Official Go Ethereum client available at https://github.com/ethereum/go-ethereum.

***“Designated Smart Contract”*** means the smart contract deployed at address [____________] on the Designated Blockchain.

***“Designated Token”*** means any amount equal to or greater than one Wei (i.e., one-quintillionth) of the Token commonly known as [“PETH”] exchanged on the Designated Blockchain.

***“Legal Order”*** means any restraining order, preliminary or permanent injunction, stay or other order, writ, injunction, judgment or decree that either: (i) is issued by a court of competent jurisdiction, or (ii) arises by operation of applicable law as if issued by a court of competent jurisdiction, including, in the case of clause “(ii)” an automatic stay imposed by applicable law upon the filing of a petition for bankruptcy.

***“Material Adverse Exception Event”*** means that one or more of the following has occurred, is occurring or would reasonably be expected to occur:

(i) a Consensus Attack adversely affecting the results or operations of the Designated Smart Contract;

(ii) the Designated Smart Contract having become inoperable, inaccessible or unusable, including as the result of any code library or repository incorporated by reference into the Designated Smart Contract or any other smart contract or oracle on which the Designated Smart Contract depends having become inoperable, inaccessible or unusable or having itself suffered a Material Adverse Exception Event, mutatis mutandis;

(iii) a material and adverse effect on the use, functionality or performance of the Designated Smart Contract as the result of any bug, defect or error in the Designated Smart Contract or the triggering, use or exploitation (whether intentional or unintentional) thereof (it being understood that for purposes of this clause “(iii)”, a bug, defect or error will be deemed material only if it results in a loss to a party to this Agreement of at least ___ percent of the Subject Property);

(iv) any unauthorized use of an administrative function or privilege of the Designated Smart Contract, including: (A) any use of any administrative credential, key, password, account or address by a Person who has misappropriated or gained unauthorized access to such administrative credential, key, password, account or address or (B) any unauthorized use of an administrative function or privilege by a Party or a representative of a Party; or

(v) the Designated Smart Contract[, any of the Parties] or the Subject Property is subject to a Legal Order that prohibits the Designated Smart Contract [(or that, if the Designated Smart Contract were a Person, would prohibit the Designated Smart Contract)] from executing any function or operation it would otherwise reasonably be expected to execute.

***“Person”*** means any human, robot, bot, artificial intelligence, corporation, partnership, association or other individual or entity recognized as having the status of a person under the law.

***“Token”*** means a digital unit that is recognized by the Designated Client on the Designated Blockchain Network as capable of: (i) being uniquely associated with or “owned” by a particular public-key address on the Designated Blockchain Network at each particular block height; and (ii) having Transfers of such digital unit recorded on the Designated Blockchain.

***“Transfer”*** of a Designated Token to a given address (the “Receiving Address”) on the Designated Blockchain Network will be deemed to have occurred if and only if it is recognized by the Designated Client on the Designated Blockchain Network that: (i) there has been duly transmitted to the Designated Blockchain Network a new transfer function transaction that:(A) provides for the reassociation of the Designated Token with the Receiving Address; and (B) is signed by a private key that is (or a group of private keys that together are) sufficient to authorize the execution of such transfer function; and (ii) such transaction has been Confirmed.

