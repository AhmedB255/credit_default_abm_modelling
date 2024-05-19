## Introduction
Despite the widespread usage of statistical models, machine learning, and deep learning approaches, making accurate predictions of borrower defaults is a critical challenge for financial institutions. It is especially important to note that borrowers do not necessarily act alone; they can also exist in social circles and have friends who can provide them with financial assistance to avoid defaulting on their loans. In this attempt, we attempt to model the process of borrower defaults using Agent-Based Modelling.

## Methodology
The agent-based model for a credit default simulation was coded in NetLogo. In the simulation, the agents, most of whom have friendships with other agents, borrow money if they don’t have debts, and make monthly payments based on the specified interest rate of the simulation. In case the borrowers can’t make a payment, they are given a second chance to repay their debts. This means that the loans’ duration is extended, but their credit score decreases. They also ask their friends for money. If their friends are willing to lend them money, the borrowers can use the money to pay off their loans. Otherwise, the borrowers default on their debts. Each tick in the simulation is equivalent to one month, and the simulation runs for 30 years.

![alt text](https://github.com/AhmedB255/credit_default_abm_modelling/blob/main/interface.png)

## Experiments
Three experiments have been conducted, each having different parameters. All experiments have had 100 repetitions and been conducted using BehaviourSpace:

1.	The first experiment included 100 borrowers all of whom borrow money at an interest rate of 4%. All the borrowers can take out a maximum loan of £25000 and the probability that their friends will lend them money is 0.5.
2.	The second experiment included 100 borrowers all of whom borrow money at an interest rate of 18%. All the borrowers can take out a maximum loan of £25000 and the probability that their friends will lend them money is 0.5.
3.	The third experiment included 100 borrowers all of whom borrow money at an interest rate of 7%. All the borrowers can take out a maximum loan of £25000 and the probability that their friends will lend them money is 1.

## Analysis
The results of the first experiment show that defaults began after the 200th month as evidenced by the default rate and the number of defaulters. We can also see that debts experienced an exponential growth which was what led to cases of default appearing. We can also see that the average balances of the borrowers had increased thanks to their monthly income and borrowing from friends. <br />

The results of the second experiment show that defaults started much earlier around the 50th month. The rest of the variables exhibited the same patterns as in the previous experiment. <br />

The results of the third experiment show that defaults started after the 100th month but before the 200th month. The rest of the variables exhibited the same patterns as in the previous experiments. <br />


