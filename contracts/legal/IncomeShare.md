<%
[[info: OLInfo]]
%>
<%
[[State: Choice("Alabama","Alaska","Arizona","Arkansas","California","Colorado","Connecticut","Delaware","District of Columbia","Florida","Georgia","Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas","Kentucky","Louisiana","Maine","Maryland","Massachusetts","Michigan","Minnesota","Mississippi","Missouri","Montana","Nebraska","Nevada","New Hampshire","New Jersey","New Mexico","New York","North Carolina","North Dakota","Northern Mariana Islands","Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island","South Carolina","South Dakota","Tennessee","Texas","Utah","Vermont","Virgin Island","Virginia","Washington","West Virginia","Wisconsin","Wyoming")]]
%>
<%
[[Entity: Choice("corporation", "limited liability company", "limited partnership", "public benefit corporation")]]
%>
<%
==Describe Education Supporter==
[[Company Name "Name of Company providing financial support?"]]
[[Company Formation "Is Education Supporter organized as Company?"]]
[[Company Formation State: State("Delaware") "Company jurisdiction?"]]
[[Company Legal Form: Entity("limited liability company") "Company legal form?"]]
[[Company Processing Agent "Company Processing Agent?"]]
[[Company Signature Email: Identity "Email for Company signature?"]]
%>
<% 
==Describe Student==
[[Student Name "Name of the Student?"]]
[[Student Mailing Address: Address "Mailing Address for Student? Type to select."]]
[[Student Signature Email: Identity "Email for Student signature?"]]
%>
<%
==Describe ISA Terms==
[[Company Financial Support: Number(60000)]]
[[Higher Education or Training: LargeText "Higher Education or Training for Student?"]]
[[Education Provider "Provider of Higher Education or Training?"]] 
[[Minimum Monthly Amount: Number(4166.67) "Minumum Monthly Amount for ISA payments?"]]
[[Income Share Percentage: Number(16) "Income Share percentage?"]]
[[Payment Cap: Number(90000) "ISA Payment Cap?"]]
[[Monthly Payments: Number(72)]]
%>
<%
==Embed DAI Payment Transfer==
[[DAI Payment "Transfer Company DAI (◈) Financial Support via ISA Execution Page?"]]
[[Company EthAddress: EthAddress "Company's Ethereum address?"]]
[[Student EthAddress: EthAddress "Student's Ethereum address?"]]
%>
<%
==Tokenize ISA==
[[Tokenize ISA "Create ERC20 Digital Artifact of ISA on Ethereum?"]]
%>
<%
==Consult with OpenEsquire==
[[OE Consult "Free Consult with OpenEsquire regarding Tokenized ISA?"]]
[[#id:Identity("info@openesq.tech")]]
%>
<%
[[@Annual Basis in Earned Income = Minimum Monthly Amount * 12]]
%>
<%
[[@Adjusted Company Financial Support = Company Financial Support * 1000000000000000000]]
%>
{{DAI Payment =>
<%
[[Transfer DAI Payment:EthereumCall(
contract:"0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359";
interface:[{"constant":false,"inputs":[{"name":"dst","type":"address"},{"name":"wad","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"}];
network:"Mainnet";
from:Company EthAddress;
function:"transfer";
arguments:Student EthAddress, Adjusted Company Financial Support)]]
%>
}}
{{Tokenize ISA =>
<%
[[Tokenize ISA on Ethereum:EthereumCall(
contract:"0xcb84a257742caf235591c42dca8cf66b470b79bc";
interface:[{"constant":false,"inputs":[{"name":"name","type":"string"},{"name":"symbol","type":"string"},{"name":"initialOwner","type":"address"}],"name":"newDigitalAsset","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"nonpayable","type":"function"}];
network:"Mainnet";
from:Company EthAddress;
function:"newDigitalAsset";
arguments:info.id, "ISA", Company EthAddress)]]
%>
}}

\centered __**INCOME SHARE AGREEMENT**__
\centered *[[info.id]]*

This Income Share Agreement ("***ISA***" or "***Agreement***") is made and entered into as of the last dated signature below, by and between [[Student Name]] (hereinafter "***Student***," "***you***," "***your***", "***I***" or "***me***") and [[Company Name]]{{Company Formation =>, a [[Company Formation State]] [[Company Legal Form]]}} (hereinafter, "***Company***," "***we***," "***our***," or "***us***", and shall include any successors or assigns of [[Company Name]]). Student and Company may sometimes be referred to in this Agreement, individually, as a "Party" and, collectively, as the "Parties," as required by context.

THIS IS A LEGAL CONTRACT. READ IT CAREFULLY BEFORE SIGNING. BY ENTERING INTO THIS AGREEMENT, YOU AGREE THAT IN RETURN FOR CERTAIN FINANCIAL SUPPORT TO COMPLETE THE HIGHER EDUCATION OR TRAINING DESCRIBED HEREIN, YOU WILL PAY A PORTION OF YOUR EARNED INCOME TO THE UNDERSIGNED COMPANY (OR THEIR DESIGNATED SUCCESSORS, SUCCESSORS-IN-INTEREST, TRANSFEREES, ASSIGNEES, AGENTS OR SERVICERS), IN ACCORDANCE WITH THE TERMS AND CONDITION SET FORTH BELOW. THIS AGREEMENT DOES NOT CONSTITUTE A LOAN OR OTHER DEBT OR CREDIT INSTRUMENT. THE AMOUNT YOU MUST PAY IS NOT A FIXED AMOUNT. INSTEAD, YOUR PAYMENT OBLIGATION IS CONTINGENT ON AND SHALL VARY BASED ON YOUR EARNED INCOME EACH YEAR, AS DESCRIBED IN THIS AGREEMENT. THE TOTAL AMOUNT YOU WLL PAY UNDER THIS AGREEMENT WILL VARY DEPENDING UPON YOUR EARNED INCOME AND MAY BE MORE OR LESS THAN THE AMOUNT OF FINANCIAL SUPPORT YOU RECEIVE.

In consideration of the financial support provided to Student as detailed below, and subject to all of the terms, covenants, promises, and conditions contained in this Agreement, Student and Company agree as follows:

^**DEFINITIONS**.

For purposes of this Agreement, the following terms shall have the meanings specified:

"Annual Earned Income" means your Earned Income for an entire calendar year.

"Approved Bank Account" has the meaning provided in *Section 4(e)* of this Agreement.

"Company" means the Person listed in the opening paragraph of this Agreement and executing this Agreement, as well as any Person to whom this Agreement may be subsequently sold or assigned.

"Derived Monthly Income" means your annual Earned Income divided by 12.

"Disability" means a determination by the Social Security Administration or other federal or state agency that you are disabled.

"Earned Income" means your total wage, compensation and self-employment gross income reported or required to be reported on an income tax return. On an annual basis for U.S. taxpayers this includes the sum of Line 7 (Wages, salaries, tips, etc.), Line 12 (Business income or loss), and Line 21 (Other income) of IRS Form 1040 or Line 1 (Wages, salaries, tips) of IRS Form 1040EZ on U.S. federal income tax returns. For the avoidance of doubt, "Earned Income" also includes any non-cash consideration received by you, directly or indirectly, or that is deemed earned, including but not limited to, contributions to qualified and non-qualified deferred compensation and retirement benefit plans, fringe benefits not reported as wages for compensation, income from your active participation in any entity, and equity rights or deferred compensation generated or attributable to the current period of your employment. Such income shall also include any amounts earned or payable, directly or indirectly to a related party as a result of your services during the year. If you file your tax return jointly with your spouse, your Earned Income shall not include any income you can demonstrate to our satisfaction is earned solely by your spouse. In our discretion, we may estimate your Earned Income using documentation other than your U.S. federal income tax return, provided the documentation is another verifiable source acceptable to us.

"Employer" means any Person for which you provide services, either as an employee or as an independent contractor, and includes any Person required by IRS regulation to provide you with a W–2 or a 1099-MISC.

"Higher Education or Training" means a program of study at a school or educational institution that is eligible under Title IV of the Higher Education Act, as amended from time to time, or a proprietary or vocational school, or a placement program that provides you the opportunity to earn Qualified Monthly Income.

"Income-Earning Month" means a month in which you earn, in the aggregate from all Employers, as a contractor or from self-employment, more than the Minimum Monthly Amount.

"Income Share" means the fixed percentage of your Qualified Monthly Earned Income that you will owe us during the Payment Term. Your "Income Share" under this Agreement is [[Income Share Percentage]]% but subject to adjustment for underreporting or overreporting of Earned Income as set forth herein.

"Industry Specific Earned Income" means, if applicable under this ISA, all Earned Income you receive from any work you perform in field(s) commonly associated with your Higher Education or Training.

"Processing Agent" means *[[Company Processing Agent]]*, which will, in connection with other third parties, be Company's processing agent with respect to this Agreement.

"Processing Agent Platform" means the processing and payment application program used by Processing Agent to provide the processing and payment functions contemplated by this Agreement, including monitoring your Earned Income in your Approved Bank Account, performing Reconciliation, and if applicable, withdrawing Monthly Payments from your Approved Bank Account.

"Minimum Monthly Amount" equals $[[Minimum Monthly Amount]], which is equivalent to $[[Annual Basis in Earned Income]] on an annual basis in Earned Income. 

"Monthly Earned Income" means the amount of Industry Specific Earned Income you receive in each month during the Payment Term. Your Monthly Earned Income will be based solely on the Earned Income you receive from work performed in field(s) commonly associated with your Higher Education or Training.

"Monthly Payment" means your Income Share times the amount of your Qualified Monthly Earned Income.

"Payment Cap" equals $[[Payment Cap]].

"Payment Term" means the term during which you pay us a fixed percentage of your Earned Income.

"Person" means any individual, partnership, corporation, limited liability company, trust or unincorporated association, joint venture or other entity or governmental body.

"Prepayment Amount" means an aggregate payment by you to Company that will extinguish your obligations under this Agreement before the Payment Term ends, which shall be the amount equal to the Payment Cap less any Monthly Payments already made plus any outstanding fees or other amounts you may owe us under this Agreement.

"Qualified Income-Earning Month" means a month in which your Monthly Earned Income exceeds the Minimum Monthly Amount.

"Qualified Monthly Earned Income" means your Monthly Earned Income in any Qualified Income-Earning Month.

"Reconciliation" has the meaning provided in *Section 5* of this Agreement.

"Student" means the individual listed in the opening paragraph of this Agreement and executing this Agreement.

^**THE PARTIES' RIGHTS AND OBLIGATIONS UNDER THIS AGREEMENT.**

^^In consideration of your execution and delivery of this Agreement, and subject to all terms and conditions set forth in this Agreement, Company agrees to provide you with the benefit of financial support in the amount of $[[Company Financial Support]] or such reasonable equivalent in digital assets ("***Financial Support***") to pursue the following Higher Education or Training: *[[Higher Education or Training]]*, with such Financial Support to be directed to the relevant account(s) of [[Education Provider]] ("***Education Provider***").

^^By entering into this Agreement and in return for receiving the benefit of the Financial Support from the Company to pursue the Higher Education or Training from the Education Provider, you agree to pay us your Income Share of your Qualified Monthly Earned Income until (i) you have made to us a total of [[Monthly Payments]].0 Monthly Payments on your Qualified Monthly Earned Income, or (ii) you reach the Payment Cap, whichever occurs first (the first to occur is referred to herein as "***Payment Satisfaction***") but subject to the provisions for Reconciliation and your obligation to make additional payment for any underreported Earned Income, as provided in *Section 5* below.

{{Tokenize ISA => ^^The Income Share is represented by one-hundred (100) ERC-20 digital tokens bearing the OpenLaw ID ascribed above and issued by execution of this ISA by the Ethereum address "0xcb84a257742caf235591c42dca8cf66b470b79bc" for the benefit of Company's Ethereum address listed at "0x[[Company EthAddress]]."}}

^**PAYMENT MANAGEMENT BY PROCESSING AGENT.**

[[Company Processing Agent]] is Company's designated processing agent for this Agreement. You hereby consent to and authorize Processing Agent to act as the agent of Company and to manage and process all requirements contemplated by this Agreement, including, but not limited to, monitoring your Earned Income in your Approved Bank Account, processing your payment obligations under this Agreement, and performing Reconciliation. You further agree to cooperate with all requests of Processing Agent in connection with processing and your compliance with all terms of this Agreement, including providing all documents or consents that may be requested of you from time to time by Processing Agent in connection with this Agreement.

^**MAKING PAYMENTS FROM YOUR EARNED INCOME.**

^^**Payment Term.** Your Payment Term will start immediately upon graduation or upon your withdrawal from the Higher Education or Training (identified in *Section 2.a*), whichever is first to occur. However, the obligation to make Monthly Payments will occur only if you are earning the Qualified Monthly Earned Income. Your Payment Term will end upon Payment Satisfaction (as described in *Section 2.b*).

^^**Reporting of all Earned Income.** Upon completion of your Higher Education or Training and throughout the Payment Term, you agree to communicate to Company and/or Processing Agent, using the Processing Agent Platform, (i) all employment positions you accept, including, if requested, a description as to the business and services or products provided by each employer and the nature of your position with each employer, (ii) your base salary for each employment position, (iii) your projected annual gross Earned Income from all Employers, including any Earned Income from self-employment, and (iv) any non-cash consideration, equity or deferred compensation rights granted to you. You further agree during the Payment Term to update, using the Processing Agent Platform, any changes in your projected gross income within thirty (30) days of any event giving rise to the expected change in your Earned Income.

^^**Monthly Payment Based on Projected Earned Income.** Based on the projected Earned Income you provide to Company and/or Processing Agent, but subject to the provisions for audit and Reconciliation (as provided in *Section 5* below), you shall pay to us a Monthly Payment, determined in accordance with your Income Share, for each month in which you have Qualified Monthly Earned Income.

^^**Methods of Payment.** Prior to but no later than the commencement of the Payment Term, you agree to elect to one of three options for payment to us of the Monthly Payment:

^^^**Automatic Withdrawal from Approved Bank Account.** You will elect to allow Processing Agent, as Company's processing agent, to automatically deduct your Monthly Payment from you Approved Bank Account, as described below; 

^^^**Credit Card Payment.** You will provide Processing Agent, as Company's processing agent, with a credit card number and execute an authorization for payment by credit card and such other documentation as may be required to authorize Processing Agent to charge Monthly Payments to your designated credit card on a recurring basis; or

^^^**Digital Assets** You will elect to utilize a digital payment method authorized by the Processing Agent in order to satisfy Monthy Payments (*e.g.*, automated transfer of "DAI" ERC-20 tokens among Ethereum blockchain network address(es)).

^^^**Withdrawal of Authorization for Auto Payments.** You have the right at any time before or during the Payment Term, subject to giving Processing Agent at least three (3) days' notice prior to a payment, to revoke your prior authorization for automatic payment from your Approved Bank Account, designated credit card, or digital asset address. Should you elect to do so, this shall not relieve you or your obligations to pay the Monthly Payment and you agree to either elect the alternate method of auto payment provided in *Section 4.d* or to send the Monthly Payment to Processing Agent via check or money order, to such address as shall be provided by Processing Agent upon receipt of your notice of withdrawal of authorization for automatic payments.

^^**Approved Bank Account.**

^^^**Set Up and Maintenance of Approved Bank Account.** You agree to establish a bank account with a financial institution or digital asset platform (*e.g.*, Ethereum blockchain network) designated or approved by Processing Agent in writing ("***Approved Bank Account***") prior to receiving any Earned Income, and also to permit integration of the Approved Bank Account with Processing Agent's Platform in order to permit Processing Agent to track your Earned income, to perform Reconciliation, and, subject to your payment election in *Section 4.d* above, to process and withdraw your Monthly Payments from your Approved Bank Account. You further agree to provide us or Processing Agent with details of the Approved Bank Account as we may reasonably request from time to time. If for any reason (*e.g.*, a change in your employment or address), you would like to change your Approved Bank Account to another bank or digital asset address, you agree to give Processing Agent prior notice of the requested change and such details for the proposed replacement account as Processing Agent may reasonably request and that the new bank account will be subject to Processing Agent’s prior approval. If at any time during the Payment Term you change your password to your Approved Bank Account or otherwise take any action that alters the ability of Processing Agent to maintain relevant access, you agree to give Processing Agent prompt notice of the change and to comply with all requests of Processing Agent to permit it to reconnect to your Approved Bank Account with the Processing Agent Platform in order to permit Processing Agent to continue to track your Earned Income, perform Reconciliation, and, as applicable, process and withdraw any payments owed pursuant to this ISA.

^^^**Right to Require Change of Approved Bank Account.** Notwithstanding the foregoing provision, and even if you already have an established Approved Bank Account, you agree that the Company and/or Processing Agent, as Company's processing agent, may require you during the Payment Term to open and maintain a new account with a financial institution or digital asset platform designated by Company and/or Processing Agent, and that you will promptly, following notice from Company and/or Processing Agent, establish a new account with the designated financial institution or digital asset platform and that such account shall then become the Approved Bank Account. You further agree to execute all such documents and consents to open the new Approved Bank Account. You also agree to authorize integration of the Approved Bank Account with the Processing Agent Platform in order for Processing Agent to monitor your Earned Income and, if you have so elected pursuant to *Section 4.d*, to authorize Processing Agent to withdraw Monthly Payments from the Approved Bank Account.

^^^**Deposit of all Earned Income into Approved Bank Account.** You agree that during the entire Payment Term you shall deposit all Earned Income received by you from any sources (whether earned as an employee or as an independent contractor) directly into your Approved Bank Account. If you are an employee, you agree to cause your Employer to arrange for the direct deposit of all of your Earned Income to your Approved Bank Account. Your refusal or failure to establish the Approved Bank Account or to permit integration with the Processing Agent platform for purposes of making Monthly Payments shall not relieve you of any of your obligations to make Monthly Payments under this Agreement.

^^^**Payment Deferrals and Extensions of Payment Term.** We shall place your ISA in deferment status and not accept payments for any month that your Monthly Earned Income does not exceed the Minimum Monthly Amount (a "***Deferred Month***"), until such time as your Monthly Earned Income exceeds, or is deemed to exceed (pursuant to a Reconciliation) the Minimum Monthly Amount, at which time your obligation to make Monthly Payments shall be reinstated. There is a 60-month limit on the aggregate number of months that Monthly Payments may be deferred. If you reach the maximum number of Deferred Months permitted under this ISA, your payment obligations under this ISA will be terminated. Certain qualifiying circumstances may also place your ISA in deferment status. For the avoidance of doubt, in the event of illness or other leave (*e.g.*, maternity or paternity leave) that may disrupt or otherwise require changes in work circumstances, we shall accomodate deferment of payments and other extensions as the circumstances may reasonably require. 

^^^**Survival of Obligations.** Expiration of the Payment Term only terminates your obligation to make Monthly Payments from Qualified Monthly Earned Income. However, it does not terminate this ISA or any continuing obligations you may have to Company or Processing Agent pursuant to this ISA, including but not limited to the obligation to make additional payment if we determine that you underreported your Earned Income.

^**RECONCILIATION.** From time to time during the Payment Term, and for a period of one (1) year following the end of the calendar year in which the Payment Term expires, Company and Processing Agent, as its processing agent, shall have the right to examine and audit your records pertaining to your employment and to verify your Earned Income at any point during the Payment Term to make sure that you have properly reported or projected your Earned Income and to verify that we have properly calculated and deducted the Monthly Payments (a "***Reconciliation***"). You agree to cooperate with Company and Processing Agent in performing any Reconciliation.

^^**Confirmation of Earned Income and Employment.** In order to perform a Reconciliation, you agree that you shall, within thirty (30) days of request:

^^^verify your Earned Income as reported to the IRS by filling out form IRS Form 4506-T or Form 4506T-EZ (or any successor form) or, if we request in the alternative, provide us with a true and accurate copy of your federal tax return as submitted to the IRS for any calendar year of the Payment Term;

^^^provide us with the name, address and phone number of any Employers from which you have received Earned Income and authorize each of your Employers to disclose to us all forms of cash and non-cash compensation paid or provided to you; and

^^^provide such other documentation (including a summary of any non-written or oral non-cash consideration, equity or deferred compensation arrangements) as may be reasonably requested by Company or Processing Agent for the purpose of performing the Reconciliation.

^^**Underreported Earned Income.**

^^^If at any time during the Payment Term and whether intentionally or unintentionally, you underreport your Earned Income to us, resulting in one or more deferred Monthly Payments, or one or more lower Monthly Payments to us than we are entitled to receive under this Agreement, we will have the right to correct the error, in our discretion, by (A) increasing your "Income Share" for Monthly Payments payable to us for each subsequent Qualified Income Earning Month, to a maximum of 150% of your defined "Income Share" percentage, or (B) retaining your Income Share percentage but adding a fixed monthly underpayment fee which shall not exceed $1,000.00 per month ("***Underpayment Fee***"), until the discrepancy in payments to us has been corrected. At such time, the Income Share percentage will revert to the original Income Share percentage as defined in *Section 1*, Definitions, or the Underpayment Fee will cease.

^^^If a Reconciliation performed by us pursuant to *Section 5* indicates that you underreported your Earned Income to us at any time during the Payment Term, so that you made one or more lower Monthly Payments to us than we are entitled to receive under this Agreement, we or Processing Agent shall give you notice within ten (10) days of completion of the Reconciliation of the amount of the underpayment and reasonable documentation of the underpayment calculation. You agree to pay us the aggregate amount of the underpayments within sixty (60) days of receiving notice of the underpayment. If you do not pay us on time, you authorize Processing Agent to deduct the amount of your underpayment from your Approved Bank Account. If the Approved Bank Account is no longer active or there are insufficient funds to pay the underpayment, we may exercise our legal rights to collect such underpayment, and you agree to pay our reasonable costs of collection, including our reasonable attorneys' fees.

^^^If a Reconciliation performed by us, or an Overpayment Claim made by you pursuant to *Section 5.c.i* below, for any year shows that your Derived Monthly Income for any month in which you made a Monthly Payment to us was less than the amount of Qualified Monthly Earned Income on which such Monthly Payment was calculated, such Monthly Payment will not be reduced or otherwise refunded unless you can demonstrate with documentation reasonably satisfactory to us that such payment was the result of a manifest error.

^^^If a Reconciliation performed for any year shows that your Derived Monthly Income for any month was more than the amount of Monthly Earned Income you reported to us for such month, your Monthly Earned Income for such month shall be deemed to equal the Derived Monthly Income, and any additional amounts payable to us will be subject to recapture pursuant to clauses (i) or (ii) above, as the case may be.

^^**Overreported Earned Income.**

^^^If at any time during the Payment Term, for any reason, you overreport your Earned Income to us, resulting in larger Monthly Payments to us than we are entitled to receive under this Agreement, you will have the right to notify us of this, and provide any documentation that we may reasonably request (including any documents we would review pursuant to a Reconciliation) in order to verify your claim of overpayment ("***Overpayment Claim***"). If, after reviewing the documents, we agree with your Overpayment Claim, we will correct the error by, in our discretion, (A) refunding the amount of the Overpayment Claim to your Approved Bank Account in a single payment or by equal payments over a period not to exceed 6 months, or (B) decreasing your "Income Share" percentage of Monthly Payments payable to us for each subsequent Qualified Income Earning Month, by not less than 10% in each Monthly Payment, until the overage in payments to us has been corrected. At such time, the Income Share Percentage, if it was previously adjusted, will revert to the original Income Share Percentage as defined in *Section 1*, *Definitions*.

^^^If the Payment Term ends prior to correction of the overage in payments under the procedure described in *Section 4(c)(i)* above, then Company shall pay you the balance of any remaining overpayment amount within thirty (30) days of the end of the Payment Term.

^^**Extension of Time for Reconciliation.** If you should file for an extension of the time to file your federal income tax returns or if you fail to provide us with the requested tax, Employer or Earned Income information or you do not otherwise reasonably cooperate with us for purposes of Reconciliation, then the one (1) period following the end of the calendar year in which the Payment Term expires shall be extended for a period of time equal to the period of time that you failed to provide the requested information or you obtained the filing extension. It is the intent of this provision that the running of the one (1) year period following the end of the calendar year in which the Payment Term expires shall be extended so that Company shall get the full and reasonable opportunity to perform Reconciliation and so that you may not benefit from your failure to comply with your obligations or you obtained the extension.

^**CAP ON PAYMENTS; PREPAYMENT AMOUNT.**

^^**Payment Cap.** The total Monthly Payments you owe under this Agreement will not exceed the Payment Cap.

^^**Prepayment Amount.** You may at any time pay in full your obligation to Company by paying an amount equal to the Payment Cap less any Monthly Payments you already made plus any outstanding amounts you may owe us, as satisfaction in full of your payment obligations under this Agreement.

^**ADDITIONAL PROVISIONS AFFECTING PAYMENTS.**

^^**Limit on Other Income Share Agreements.** You agree that you have not and will not enter into additional income share agreements or similar arrangements with us or another Person that, in the aggregate, obligate you to pay a total Income Share exceeding 30.0% percent of your Earned Income.

^^**International Work.** If you move out of the United States during your Payment Term, you agree to continue to report Earned Income and to continue paying your Income Share of your Qualified Monthly Earned Income, and you shall not be in Breach of this Agreement so long as you continue to make the required Monthly Payments.

^^**Waiver of ISA Due to Death or Total and Disability.** We will waive what you owe under this Agreement, including any past due amounts and fees, if you die or become disabled. If you would like to assert a waiver based on disability, you will need to provide documentation showing that you have been found to be disabled by the Social Security Administration or other federal or state agency due to a condition that began or deteriorated after the date of signing this Agreement and that the disability is expected to be permanent.

^^**Obligation in Event of Withdrawal.** If for any reason and at any time you withdraw from the Higher Education or Training related to this Agreement, you may be entitled to a *pro rata* reduction in your committed Income Share percentage or the length of the Payment Term, but solely at the discretion of the Company. You agree to give the Company and Processing Agent prompt notice of your withdrawal from the Higher Education or Training and the effective date of your withdrawal.

^**REVIEW OF YOUR TAX RETURNS.** For the tax year in which your Payment Term begins through the tax year in which your Payment Term ends, you agree to file your U.S. federal income tax returns, no later than April 15 of the following year, and to timely file any state or local tax returns by the date they are due. You agree to notify us of any extension you seek for filing federal income tax returns. Moreover, upon our or Processing Agent's request, you agree to sign and file IRS Form 4506-T or Form 4506T-EZ (or any successor form) within thirty (30) days of request, designating each of the Company (or its then-applicable Assignee) and Processing Agent as the designated recipients of your tax return information for returns covering any and all years of your Payment Term. You agree to perform any similar requirements or procedures for any other applicable country's taxing authority.

^**TAX REPORTING.** Company intends to report the tax consequence of the ISA on its tax returns as a financial contract that is eligible for open transaction treatment. Company believes that this tax treatment is more likely than not the proper characterization for federal income tax purposes. We urge you to consult with your own tax advisors, to ascertain the appropriate manner in which to report your taxes. We believe that there is a potential benefit if all parties to a transaction report in a consistent fashion. We encourage you to report in a manner that is consistent for all parties to the transaction. We recognize that there may be specific situations where Company or you may find it appropriate to report in a way that is inconsistent with the other Party. You are once again, urged to consult with your tax advisors about the potential consequences of such reporting.

^**COVENANTS AND REPRESENTATIONS OF STUDENT.** By entering into this Agreement, you represent, warrant and promise to the Company as follows:

^^that you are entering into this Agreement in good faith and with the intention to pay us by making Monthly Payments when due;

^^that all the information you have provided to Company in connection with entering into this Agreement is true and accurate and that you have not provided any false, misleading or deceptive statements or omissions of fact, including, but not limited to, your engagement with the Education Provider to complete the Higher Education or Training;

^^that you have never been convicted of a felony or of any crime involving dishonesty or breach of trust under any federal or state statute, rule or regulation;

^^that you are not contemplating bankruptcy and you have not consulted with an attorney regarding bankruptcy in the past six months;

^^that you will make reasonable and good faith efforts to seek employment immediately following completion of the Higher Education or Training and during all times during the Payment Term that you are not employed or that you have Earned Income less than the Minimum Monthly Amount;

^^during the Payment Term, you will timely report to Processing Agent any changes in your Employment status;

^^during the Payment Term, you will not conceal, divert, defer or transfer any of your Earned Income (including but not limited to any non-cash consideration, equity or deferred compensation rights granted to you) for the purpose of avoiding or reducing your Monthly Payment obligation or otherwise;

^^that you will timely and fully provide all information and documentation required under the terms of this Agreement or as reasonably requested by Company (including any assignee of Company) and/or Processing Agent, and that such information or documentation shall be true, complete, and accurate;

^^that during the Payment Term you will file all federal, state or local tax returns and reports as required by law, which shall be are true and correct in all material respects, that you will report all of your Earned Income on such returns, and that you shall pay all federal, state or local taxes and other assessments when due;

^^that you shall keep accurate records relating to your Earned Income for each year of your Payment Term, including all W-2s, pay stubs, and any invoices or payments relating to self-employment services you provide; and

^^that you will retain all such records for a period of at least one (1) year following the date you fulfill all your payment obligations under this Agreement.

^**COVENANTS AND REPRESENTATIONS OF COMPANY.** Company represents, warrants and promises to Student as follows:

^^**Confidentiality.** Company agrees that all employment or financial information of Student and any non-public records or information provided to us pursuant to this Agreement is personal and confidential information. Company agrees not to, directly or indirectly, disclose, publish, cause to be disclosed or published, or use personal or financial information concerning you or your Employer for any purposes other than (i) as expressly authorized herein, (ii) as incidental to performance of this Agreement, including providing confidential information to any assignee of this Agreement, or (iii) to enforce its rights under this Agreement.

^^**Security.** Company and Processing Agent shall use and maintain commercially reasonable security controls so as to prevent any unauthorized access to or use any personal and confidential information of Student.

^**BREACH AND REMEDIES**.

^^**Breach.** Without prejudice to our other rights and remedies hereunder, and subject to applicable law, we may deem you to be in breach under this Agreement (a "***Breach***") upon any of: (i) your failure to make any Monthly Payment that is due under this Agreement, in full and on time, within ninety (90) days of the due date; (ii) your failure to provide Earned Income documentation within ninety (90) days of its due date; (iii) your failure to provide us a completed and executed IRS Form 4506-T, your social security number, or the name of your Employer(s) within ninety (90) days of our request; (iv) your failure to provide details of and confirm ownership of your Approved Bank Account, or otherwise comply with *Section 3(c)* of this Agreement within ninety (90) days of receiving written notice from us or Processing Agent of such failure; or (v) your violation of any other provision of this Agreement that impairs our rights, including but not limited to our receipt of information we deem, in our sole discretion, to be materially false, misleading or deceptive.

^^**Remedies upon Breach.** Subject to applicable law (including any notice and/or cure rights provided by applicable law), upon Breach, we will be entitled to (i) collect the Prepayment Amount, less any Monthly Payments already made and plus any outstanding fees or other amounts you may owe us, (ii) enforce all legal rights and remedies in the collection of such amount and related fees (including any rights available to us to garnish wages or set off any federal or state tax refund) or (iii) utilize any combination of these remedies. You agree to pay our court costs, reasonable attorneys' fees, collection fees charged by states for state tax refund set-off, and other collection costs related to the Breach (including our fees and costs due to your bankruptcy or insolvency, if applicable) to the extent permitted by applicable law.

^^**Equitable Remedies.** If we conclude that money damages are not a sufficient remedy for any particular Breach of this Agreement, then we will be entitled to seek an accounting, as well as injunctive or other equitable relief that may be applicable as a remedy for any such breach to the fullest extent permitted by applicable law. Such remedy shall be in addition to all other remedies available at law or equity to us.

^**RETAINED RIGHTS.** No Breach or the termination of this Agreement will affect the validity of any of your accrued obligations owing to Company under this Agreement. Notwithstanding termination of the Payment Term, Company or any Person to which this Agreement is assigned shall retain all rights to enforce your obligations under this Agreement, including the right to receive the full amount of your Income Share owing hereunder based on your Earned Income during the Payment Term.

^**ELECTRONIC DELIVERY.** We may decide to deliver any documents or notices related to this Agreement by electronic means. You agree to receive such documents or notices by electronic delivery to the email address provided us and Processing Agent, and to participate through an on-line or electronic system established and maintained by us or Processing Agent.

^**PERMITTED COMMUNICATIONS.** We or Processing Agent may use automated telephone dialing, text messaging systems and electronic mail to provide messages to you about payment due dates, missed payments and other important information. The telephone messages may be played by a machine automatically when the telephone is answered, whether answered by you or someone else. These messages may also be recorded in your voicemail. You give us and Processing Agent your permission to call or send a text message to any telephone number you provide us now or in the future and to play pre-recorded messages or send text messages with information about this Agreement over the phone. You also give us permission to communicate such information to you via electronic mail. You agree that we and Processing Agent will not be liable to you for any such calls or electronic communications, even if information is communicated to an unintended recipient. You understand that, when you receive such calls or electronic communications, you may incur a charge from the company that provides you with telecommunications, wireless and/or Internet services. You agree that we and Processing Agent shall have no liability for such charges. You also agree that we and our agents, including but not limited to Processing Agent, may record any telephone conversations we may have with you. You may withdraw your consent to receiving telephone calls or texts via an automatic telephone dialing system ("***ATDS***") to your cell phone at any time by sending a revocation notice by email to such email address as the Company or Processing Agent may provide to you from time to time. That revocation notice must include (i) your name and address, (ii) your cellular telephone number(s), and (iii) your account number, if applicable; and shall expressly state that you are revoking your consent for the Company or Processing Agent to make calls or text via an ATDS to your cell phone as authorized by this *Section 15*.

^**CONSENT TO CREDIT AND INCOME VERIFICATION; CREDIT REPORTING; STUDENT INFORMATION.**

^^In connection with the provision of the Higher Education or Training and entering into this Agreement, you authorize Company, Processing Agent, or a prospective assignee of this Agreement (each, an "***Authorized Party***") to obtain your credit report, verify the information that you provide to Company, and gather such additional information that an Authorized Party reasonably determines may help that Authorized Party assess and understand your ability to perform your obligations under this Agreement. You understand that an Authorized Party may verify your information and obtain additional information using a number of sources, including but not limited to consumer reporting agencies, other third party databases, past and present employers, other school registrars, public sources, and personal references provided by you. If you ask, you will be informed whether or not an Authorized Party obtained a credit report and, if so, the name and address of the consumer reporting agency that furnished the report. You further authorize an Authorized Party sharing of your credit report and information therein with its assigns or affiliates (including but not limited to its parents, investors, and lenders), which the Authorized Party will do using reasonable data security procedures.

^^You authorize Company and its agents (including but not limited to Processing Agent) to report information about this Agreement to credit bureaus. Although this Agreement is not "credit," we may inform credit bureaus about your positive payment behavior when you make payments as agreed. However, this also means that late payments, missed payments, or other Breaches under this Agreement may be reflected in your credit report.

^^You authorize Company to use any and all information provided by you, and any data derived from such information, for any purpose, including, without limitation, creation of any additional products or services derived therefrom. You disclaim any proprietary or monetary interest in any such additional products or services.

^**CUSTOMER IDENTIFICATION POLICY.** To help the government fight the funding of terrorism and money laundering activities, we will obtain, verify and record information that identifies each person who enters into this Agreement. What this means for you: when you enter into this Agreement, we reserve the right to ask for your name, address, date of birth, Social Security number, and other information that will allow us to identify you. We may also ask to see your driver's license or other identifying documents.

^**NOTICE AND CURE.** Prior to initiating a lawsuit or arbitration regarding a Claim (as defined in *Section 19*, "***Arbitration Agreement***" below), the Party asserting the Claim (the "***Complaining Party***") shall give the other Party (the "***Defending Party***") written notice of the Claim (a "***Claim Notice***") and a reasonable opportunity, not less than thirty (30) days, to resolve the Claim. If we are the Complaining Party, we will send the Claim Notice to you at your address appearing in our records or, if you are known to be represented by an attorney, to your attorney at his or her office address. Any Claim Notice must explain the nature of the Claim and the relief that is demanded. The Complaining Party must reasonably cooperate in providing any information about the Claim that the Defending Party reasonably requests. The provisions of this *Section 18* shall survive termination of this Agreement.

^**ARBITRATION OF CLAIMS AGAINST COMPANY.** Except as expressly provided below, Student agrees that any past, present or future claim, dispute or controversy Student may have against the Company, regardless of the legal theory on which it is based, arising out of, relating to or occurring in connection with this Agreement (a "***Claim***"), shall be submitted to and resolved by binding arbitration under the Federal Arbitration Act, 9 U.S.C. §§1 *et seq.* (the "***FAA***") before the American Arbitration Association (the "***AAA***") under its Consumer Arbitration Rules in effect at the time the arbitration is brought (the "***AAA Rules***", which are available online at www.adr.org). If the AAA is unable to serve as administrator and the Company and the Student cannot agree on a replacement, a court with jurisdiction will select the administrator or arbitrator. This means that any Claim you have shall be resolved by a neutral third-party arbitrator, and not by a judge or a jury, and you hereby knowingly and voluntarily waive the right to trial on such Claim any court of law or equity. 

For purposes of this Arbitration Agreement: (a) the term "Claim" has the broadest possible meaning, and includes initial claims, counterclaims, cross-claims and third-party claims. It includes disputes based upon contract, tort, consumer rights, fraud and other intentional torts, constitution, statute, regulation, ordinance, common law and equity (including any claim for injunctive or declaratory relief). For purposes of this Arbitration Agreement; (b) the term "Company" includes (i) Company, (ii) any assignee of this Agreement, (iii) any assignee, agent, designee or servicer of Company (including but not limited to Processing Agent), (iv) the officers, directors, employees, affiliates, subsidiaries, and parents of all of the foregoing, and (e) any Person named as a co-defendant with Company in a Claim asserted by the Student, such as servicers and debt collectors; and (c) the term "Student" means the Student executing this Agreement. Notwithstanding the above, if a Claim that the Student wishes to assert against the Company is cognizable in a small claims court (or your state's equivalent court) having jurisdiction over the Claim and the Parties, the Student or the Company may pursue such Claim in that small claims court; provided, however, that if the Claim is transferred, removed, or appealed to a different court, it shall then be resolved by arbitration. Moreover, any dispute concerning the validity or enforceability of this Arbitration Agreement must be decided by a court; any dispute concerning the validity or enforceability of the ISA as a whole is for the arbitrator.

Any arbitration hearing that you attend will take place before a single arbitrator and shall be held in the same city as the U.S. District Court closest to your address. If you cannot obtain a waiver of the AAA's or arbitrator's filing, administrative, hearing and/or other fees, we will consider in good faith any request by you for us to bear such fees. Each Party will bear the expense of its own attorneys, experts and witnesses, regardless of which Party prevails, unless applicable law or this Agreement gives a right to recover any of those fees from the other Party.

The arbitrator shall follow applicable substantive law to the extent consistent with the FAA, applicable statutes of limitation and privilege rules that would apply in a court proceeding, but subject to any limitations as may be set forth in this Agreement.

This Arbitration Agreement shall survive the termination of this Agreement, your fulfillment of your obligations under this Agreement and/or your or our bankruptcy or insolvency (to the extent permitted by applicable law). In the event of any conflict or inconsistency between this Arbitration Agreement and the administrator's rules or other provisions of this Agreement, this Arbitration Agreement will govern.

CLASS ACTION WAIVER: IF A CLAIM IS ARBITRATED, STUDENT WILL NOT HAVE THE RIGHT TO PARTICIPATE IN A CLASS ACTION, A PRIVATE ATTORNEY GENERAL ACTION OR OTHER REPRESENTATIVE ACTION IN COURT OR IN ARBITRATION, EITHER AS A CLASS REPRESENTATIVE OR CLASS MEMBER. 

Further, unless both Student and the Company agree otherwise in writing, the arbitrator may not join or consolidate Claims with claims of any other persons. The arbitrator shall have no authority to conduct any class, private attorney general or other representative proceeding, and shall award declaratory or injunctive relief only to the extent necessary to provide relief warranted by that Student's individual Claim. If a determination is made in a proceeding involving the Company and the Student that the class action waiver is invalid or unenforceable, only this sentence of this Arbitration Agreement will remain in force and the remainder of this Arbitration Agreement shall be null and void, provided, that the determination concerning the class action waiver shall be subject to appeal.

RIGHT TO REJECT: You may reject this Arbitration Agreement by emailing a rejection notice to Company at such email address as Company or Processing Agent may provide to you from time to time within thirty (30) calendar days after the date of full execution of this Agreement. Any rejection notice must include (i) your name and address, (ii) your cellular telephone number(s); (iii) your account number, if applicable; and shall state that you are rejecting this Arbitration Agreement in your Agreement. If you reject this Arbitration Agreement, that will not affect any other provisions of the ISA or your obligations under this Agreement.

^LIMITATION OF LIABILITY. EXCEPT TO THE EXTENT CAUSED BY THE WILLFUL MISCONDUCT OF COMPANY OR PROCESSING AGENT, NEITHER COMPANY NOR PROCESSING AGENT SHALL BE LIABLE TO STUDENT FOR LOSS OF EMPLOYMENT, LOST INCOME OR PROFITS, CONSEQUENTIAL, EXEMPLARY, INCIDENTAL, INDIRECT, OR SPECIAL DAMAGES, EVEN IF ADVISED BY STUDENT OF THE POSSIBILITY OF SUCH DAMAGES. THE PROVISIONS OF THIS SECTION 20 SHALL SURVIVE TERMINATION OF THIS AGREEMENT.

^**SURVIVAL OF CERTAIN PROVISIONS.** Notwithstanding anything to the contrary in this Agreement, the provisions of *Sections 3* (Payment Management by Processing Agent), *5* (Reconciliation), *9* (Tax Reporting), *10* (Covenants and Representations of Student), *12* (Breach and Remedies), *13* (Retained Rights), *14* (Electronic Delivery), *18* (Notice and Cure), *19* (Arbitration), *20* (Limitation of Liability) and *21* (General Provisions) shall survive termination of this Agreement, your fulfillment of your obligations under this Agreement and/or your or our bankruptcy or insolvency (to the extent permitted by applicable law).

^**GENERAL PROVISIONS.**

^^**Entire Agreement.** This Agreement sets forth the entire agreement and understanding of the Parties relating to the subject matter herein and supersedes all prior or contemporaneous discussions, understandings and agreements, whether oral or written, between you and us relating to the subject matter hereof.

^^**Amendments.** This Agreement cannot be modified or amended except with the written consent of both Parties.

^^**No Waivers.** No delay or failure on the part of either Party to require performance of any provision of this Agreement shall constitute a waiver of that provision as to that or any other instance.

^^**Successors and Assigns.** We (and any Person that acquires a majority interest of the equity of Company or substantially all of its assets), may sell and/or assign this Agreement and/or any of our rights, economic benefits or obligations under this Agreement, to any other Person without your permission or consent{{Tokenize ISA =>, which may be accomplished by transfer of the ERC-20 digital tokens issued hereby bearing the OpenLaw ID ascribed above}}. However, you may not assign this Agreement, whether voluntarily or by operation of law, or any of your rights, economic benefits (including, but not limited to, the Financial Support or the Higher Education or Training) or obligations under this Agreement, except with our prior written consent. Except as otherwise provided in this Agreement, this Agreement, and the rights and obligations of the Parties hereunder, will be binding upon and inure to the benefit of their respective successors, assigns, heirs, executors, administrators and legal representatives.

^^**Severability.** Except as set forth in the in *Section 19* (Arbitration), if one or more provisions of this Agreement are held to be unenforceable under applicable law or the application thereof to any Person or circumstance shall be invalid or unenforceable to any extent, then (i) such provision shall be excluded from this Agreement to the minimum extent necessary so that this Agreement will otherwise remain in full force and effect and enforceable, (ii) the balance of this Agreement shall be interpreted as if such provision were so excluded and (iii) the remainder of this Agreement shall be enforceable in accordance with its terms.

^^**Governing Law.** The validity, interpretation, construction and performance of this Agreement, and all acts and transactions pursuant to this Agreement and the rights and obligations of the Parties under this Agreement shall be governed by, construed and interpreted in accordance with the laws of Delaware, without giving effect to principles of conflicts of law.

^^**Notices.** Any notice, consent, demand or request required or permitted to be given under this Agreement shall be in writing and, except as otherwise provided, shall be deemed sufficient (i) when sent by email from you to Processing Agent, as Company's processing agent, at such email address as Company or Processing Agent may provide to you from time to time, and (ii) when sent by Company or Processing Agent to you via email at the email address you last provided to Company or Processing Agent.

^^**Execution; Electronic Transactions.** This Agreement may be executed electronically or manually. Execution may be completed in counterparts (including both counterparts that are executed on paper and counterparts that are electronic records and executed electronically), which together shall constitute a single agreement. Any copy of this Agreement (including a copy printed from an image of this Agreement that has been stored electronically) shall have the same legal effect as an original.

\centered *[Acknowledgment of Student and Signatures of Parties on next page]*

\centered *[Remainder of page intentionally left blank]*
\pagebreak
\centered **VERIFICATION OF REVIEW AND INDEPENDENT DECISION TO ENTER INTO ISA**

By signing below, Student acknowledges and agrees that this Agreement is entered into voluntarily and as an arms-length transaction. Student further acknowledges and agrees with each of the following: (i) that I am of legal age to execute this Agreement; (ii) that I have had the opportunity to read this Agreement and to review its terms with my legal and financial advisors of my choosing; (iii) that Company is not an agent or fiduciary or advisor acting for my benefit or in my favor in connection with the execution of this Agreement; (iv) that Company has not provided me with any legal, accounting, investment, regulatory or tax advice with respect to this Agreement; (v) that Company has not made any promises or assurances to me that are not expressly set forth in writing in this Agreement; and (vi) that I understand that by entering into this this Agreement, I am irrevocably agreeing to share a fixed portion of my future Earned Income in consideration of Financial Support to benefit my Higher Education or Training, in accordance with all of the terms and conditions set forth in this Agreement.

IN WITNESS WHEREOF, the Parties have entered into this Income Share Agreement effective as of the date of Student's execution.

{{DAI Payment => [[Transfer DAI Payment]]}}
{{Tokenize ISA => [[Tokenize ISA on Ethereum]]}}

**Company:** **[[Company Name]]**
_______________________________

Signed: *[[Company Signature Email: Identity | Signature]]*
             
{{Company Formation => Title: Authorized Signatory}}


**Student:** **[[Student Name]]**
_______________________________

Signed: *[[Student Signature Email: Identity | Signature]]*

Address: [[Student Mailing Address]]

{{OE Consult => '''Send your draft ISA template to info@openesq.tech so we may consult with you on Tokenized ISA 🖖'''
[[#id:Identity("info@openesq.tech")]]    
}}
