;; The Borrowers breed
;; It has eight variables; credit-score, debt, balance, income, debt-duration, has-defaulted, new-loan-probability, and friendship-probability
;; All of which are explained in the ODD protocol
breed [ borrowers borrower ]
borrowers-own [ credit-score debt balance income debt-duration has-defaulted new-loan-probability friendship-probability ]

;; Global variables
;; Variables used by the entire system
globals [
  min-credit-score
  max-credit-score
  current-tick
]

;; *************************************** SETUP PROCEDURE ****************************************************
;; It designs a very simple world filled with borrowers, most of which, if not all, are friends with each other
;; It is also used to set the values of the varriables above
to setup
  clear-all
  ask patches [ set pcolor 33 ]
  set-global-variables
  create-borrowers number-of-borrowers [
    set shape "person"
    set color blue
    setxy random-xcor random-ycor
    set credit-score 300 + random (850 - 300 + 1)
    if credit-score > max-credit-score [ set credit-score credit-score = max-credit-score ]
    set debt 0
    set balance 50000 - (credit-score * 50)
    set income 5000 + (credit-score * 5)
    set has-defaulted false
    set new-loan-probability random-float 1
    set debt-duration 1
    set friendship-probability random-float 1
  ]
  create-friendships
  reset-ticks
end

;; *************************************** TURTLE PROCEDURES ****************************************************

;; The SET-GLOBAL-VARIABLES procedure sets the values of the global variables
to set-global-variables
  set min-credit-score 300
  set max-credit-score 850
  set current-tick 0
end

;; The CREATE-FRIENDSHIPS procedure establishes relationships between borrowers based on their FRIENDSHIP-PROBABILITY
;; I don't all borrowers to have friendships with each other, which is why I used a value of 0.7 as a base
to create-friendships
  ask borrowers with [ friendship-probability >= 0.7 ] [
    create-links-with other borrowers with [ friendship-probability >= 0.7 ]
  ]
  ask links [
    set thickness 0
    set color gray
  ]
end

;; The PAY-DEBT procedure allows borrowers to pay their due debts
;; Paying debts affects a borrower's balance
;; monthly-payment is a report found below in the reporters section
to pay-debt
  set balance balance - monthly-payment
end

;; The DECREASE-CREDIT-SCORE procedure is called whenever a borrower defaults on their debt to decrease their credit score
;; However, the credit score cannot be below a certain threshold (300)
to decrease-credit-score
  set credit-score credit-score - random 250
  if credit-score < min-credit-score [ set credit-score min-credit-score ]
end

;; The BECOME-DEFAULTER procedure is called whenever a borrower defaults on their debt
;; Marks them as defaulters by changing their colour from blue to red
to become-defaulter
  set color red
  set has-defaulted true
end

;; The GET-SECOND-CHANCE procedure is called whenever a borrower is about to default on their debt
;; Extends the duration of the debt, decreases the credit score, and the borrower is allowed to ask friends for money
to get-second-chance
  set debt-duration debt-duration + 1
  decrease-credit-score
  ask-friends-for-money
end

;; The ASK-FRIENDS-FOR-MONEY procedure is called if a borrower cannot make a payment, but has friends that they can ask for money to pay their debts
;; These types of loans are not considered to be part of the loans that a bank would keep track of
;; So if they are not able to pay back the loans they make to their friends (this feature is not implemented here),
;; they are not considered defaulters
;; If their friends do not lend them money, this means they are not able to pay for loans they borrowed from a bank
;; In that case, they become defaulters
to ask-friends-for-money
  ask borrowers with [ has-defaulted = false ] [
    let lending-amount 0
    ask link-neighbors [
      let my-balance [ balance ] of myself
      let my-debt [ debt ] of myself
      if friend-lending-probability > random-float 1 and balance > my-balance and balance > my-debt and has-defaulted = false [
        set balance balance - my-debt
        set lending-amount my-debt
      ]
    ]
    set balance balance + lending-amount
    ifelse can-afford-payment? [
      pay-debt
    ]
    [ decrease-credit-score become-defaulter ]
  ]
end

;; The WIGGLE procedure is used to make the borrowers move (to simulate real humans)
to wiggle
  right random 90
  left random 90
end

;; The GET-NEW-LOAN procedure is the first procedure called in the GO procedure
;; It is implemented such that all borrowers must obtain a loan if they don't have debts
to get-new-loan
  ask borrowers [
    if random-float 1 > new-loan-probability and any? borrowers with [ debt = 0 and has-defaulted = false ] [
      let potential-loan-amount max-loan-amount-for-credit-score credit-score
      set debt debt + potential-loan-amount
      set debt-duration debt-duration + 1
      set balance balance + potential-loan-amount
    ]
  ]
end

;; The BALANCE-CHECK procedure is the second procedure called in the GO procedure
;; It adds the borrower's income to their balance and checks whether they can afford to make a payment or not
to balance-check
  ask borrowers [ set balance balance + income ]
  ask borrowers with [ has-defaulted = false and debt != 0 ] [
      ifelse can-afford-payment? [ pay-debt ] [ get-second-chance ]
  ]
end

;; *************************************** TURTLE REPORTERS ****************************************************

;; The CAN-AFFORD-PAYMENT? reporter is used to determine if a borrower has enough balance to make their monthly payment
to-report can-afford-payment?
  report (balance != 0 and debt > 0 and balance >= debt)
end

;; The GET-DEFAULTERS reporter is used to return the number of borrowers who have defaulted
to-report get-defaulters
  report (count borrowers with [ color = red ])
end

;; The GET-DEFAULT-RATE reporter is used to obtain the default rate through this equation:
;; number of people who have defaulted / the total number of borrowers
to-report get-default-rate
  let total-borrowers count borrowers
  let num-defaulted count turtles with [has-defaulted]
  let default-rate 0
  if total-borrowers > 0 [
    set default-rate num-defaulted / total-borrowers
  ]
  report default-rate
end

;; Similar to CAN-AFFORD-PAYMENT?, BORROWERS-CAN-AFFORD-PAYMENT is used to return the total number of borrowers who can afford to make their payment
;; Mainly used as a metric to gauge the performance of borrowers in the simulation
to-report borrowers-can-afford-payment
  report (count borrowers with [ balance != 0 and debt > 0 and balance >= debt ])
end

;; The MEAN-CREDIT-SCORES reporter returns the average value of the credit scores
to-report mean-credit-scores
  report (mean [ credit-score ] of borrowers)
end

;; The STD-CREDIT-SCORES reporter returns the standard deviation of the credit scores
to-report std-credit-scores
  report (standard-deviation [ credit-score ] of borrowers)
end

;; The MEAN-BALANCES reporter returns the average value of the borrowers' balances
to-report mean-balances
  report (mean [ balance ] of borrowers)
end

;; The STD-BALANCES reporter returns the standard deviation of the borrowers' balances
to-report std-balances
  report (standard-deviation [ balance ] of borrowers)
end

;; The MEAN-DEBTS reporter returns the average value of the borrowers' debts
to-report mean-debts
  report (mean [ debt ] of borrowers)
end

;; The STD-DEBTS reporter returns the standard deviation of the borrowers' debts
to-report std-debts
  report (standard-deviation [ debt ] of borrowers)
end

;; The MEAN-INCOMES reporter returns the average value of the borrowers' incomes
to-report mean-incomes
  report (mean [ income ] of borrowers)
end

;; The STD-INCOMES reporter returns the standard deviation of the borrowers' incomes
to-report std-incomes
  report (standard-deviation [ income ] of borrowers)
end

;; The MONTHLY-PAYMENT reporter calculates the monthly interest rate and monthly payment multiplier
to-report monthly-payment
  let monthly-interest-rate annual-interest-rate / 1200
  let debt-duration-months debt-duration * 12
  let monthly-payment-multiplier (monthly-interest-rate * ((1 + monthly-interest-rate) ^ debt-duration-months)) / (((1 + monthly-interest-rate) ^ debt-duration-months) - 1)
  report debt * monthly-payment-multiplier
end

;; The MAX-LOAN-AMOUNT-FOR-CREDIT-SCORE reporter calculates the maximum loan that a borrower should receive depending on their credit score
to-report max-loan-amount-for-credit-score [ this-credit-score ]
  report max-loan-amount * ((this-credit-score - min-credit-score) / (max-credit-score - min-credit-score))
end

;; *************************************** GO PROCEDURE ****************************************************
;; Checks if all borrowers have defaulted or not or if 361 months (30 years) have past to end the simulation
;; If both conditions are false the borrowers move around to simulate human movement
;; The procedure also run GET-NEW-LOAN and BALANCE-CHECK in that order as discussed in the ODD protocol
to go
  if all? borrowers [ has-defaulted = true ] or current-tick = 361 [ stop ]
  ask borrowers [
    wiggle
    forward 0.5
  ]
  get-new-loan
  balance-check
  set current-tick current-tick + 1
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
229
10
659
441
-1
-1
12.8
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
25
11
88
44
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
106
11
169
44
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
55
56
130
89
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
16
104
191
137
number-of-borrowers
number-of-borrowers
0
300
100.0
1
1
NIL
HORIZONTAL

PLOT
675
16
959
192
overall-rate-of-default
time
default-rate
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"average" 1.0 0 -2674135 true "" "if ticks != 0 [plot mean [get-default-rate] of turtles]"
"max" 1.0 0 -14070903 true "" "if ticks != 0 [plot max [get-default-rate] of turtles]"
"min" 1.0 0 -14439633 true "" "if ticks != 0 [plot min [get-default-rate] of turtles]"
"std" 1.0 0 -4079321 true "" "if ticks != 0 [plot standard-deviation [get-default-rate] of turtles]"

SLIDER
14
147
192
180
annual-interest-rate
annual-interest-rate
1
20
7.0
1
1
%
HORIZONTAL

MONITOR
285
451
417
496
number-of-defaulters
get-defaulters
17
1
11

MONITOR
424
451
586
496
borrowers-can-afford-payment
borrowers-can-afford-payment
17
1
11

MONITOR
14
283
120
328
NIL
mean-credit-scores
17
1
11

MONITOR
15
338
101
383
NIL
mean-balances
3
1
11

MONITOR
15
393
90
438
NIL
mean-debts
3
1
11

MONITOR
129
283
223
328
NIL
std-credit-scores
3
1
11

MONITOR
108
338
185
383
NIL
std-balances
3
1
11

MONITOR
99
393
177
438
NIL
std-debts
3
1
11

SLIDER
13
190
193
223
friend-lending-probability
friend-lending-probability
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
14
233
193
266
max-loan-amount
max-loan-amount
0
25000
25000.0
1000
1
£
HORIZONTAL

PLOT
675
194
961
346
balances-over-time
time
blances
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"average" 1.0 0 -5298144 true "" "plot mean [balance] of borrowers"
"max" 1.0 0 -14730904 true "" "plot max [balance] of borrowers"
"min" 1.0 0 -15040220 true "" "plot min [balance] of borrowers"
"std" 1.0 0 -7171555 true "" "plot standard-deviation [balance] of borrowers"

PLOT
991
194
1277
346
credit-scores-over-time
time
credit-scores
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"average" 1.0 0 -8053223 true "" "plot mean [credit-score] of borrowers"
"max" 1.0 0 -14730904 true "" "plot max [credit-score] of borrowers"
"min" 1.0 0 -15040220 true "" "plot min [credit-score] of borrowers"
"std" 1.0 0 -7171555 true "" "plot standard-deviation [credit-score] of borrowers"

PLOT
989
16
1275
189
debt-over-time
time
debts
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"average" 1.0 0 -8053223 true "" "plot mean [debt] of borrowers"
"max" 1.0 0 -14730904 true "" "plot max [debt] of borrowers"
"min" 1.0 0 -15040220 true "" "plot min [debt] of borrowers"
"std" 1.0 0 -7171555 true "" "plot standard-deviation [debt] of borrowers"

MONITOR
14
447
97
492
NIL
mean-incomes
3
1
11

MONITOR
105
447
184
492
NIL
std-incomes
3
1
11

PLOT
674
352
1278
502
income-over-time
time
incomes
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"average" 1.0 0 -8053223 true "" "plot mean [income] of borrowers"
"max" 1.0 0 -14730904 true "" "plot max [income] of borrowers"
"min" 1.0 0 -15040220 true "" "plot min [income] of borrowers"
"std" 1.0 0 -7171555 true "" "plot standard-deviation [income] of borrowers"

@#$#@#$#@
# ODD Protocol for Credit Default Simulation

## Purpose and patterns

The goal of this model is the exploration of credit defaults using a simulation consisting of borrowers, each of which has a certain credit score, which is assigned randomly to them in a range from 300 to 850. Based on their credit score, borrowers are given an initial balance, which they then use to make monthly payments to pay off their loans. In case they can't make their payments, the debt duration increases, their credit scores increase, and they ask their friends for money to pay off the loans. Otherwise, their respective credit scores start to decrease and their debt starts to increase until they default.

It is important to note that this is a theoretical model; it does not seek to explain the entire process because credit default analysis is an inherently complex process affected by a large number of variables. The results of this model do not provide any recommendations to firms and regulators of what measures must be taken to mitigate credit defaults.

## Entities, state variables, and scales

In this model, we have only one breed which is the borrowers breed. All borrowers have seven state variables. The table below provides a clear overview of the variables used in the model.

**Table 1. Model state variables**
<table style="border-collapse: collapse; margin-left: 10px;">
  <tr style="border: 1px solid black;" align="center">
    <th style="border: 1px solid black;">Variable name</th>
    <th style="border: 1px solid black;">Type</th>
    <th style="border: 1px solid black;">Units</th>
    <th style="border: 1px solid black;">Range</th>
    <th style="border: 1px solid black;">Meaning/rationale</th>
  </tr>
  <tr style="border: 1px solid black;" align="center">
    <td style="border: 1px solid black;">xcor</td>
    <td style="border: 1px solid black;">Integer; static</td>
    <td style="border: 1px solid black;">No unit</td>
    <td style="border: 1px solid black;">Any in environment</td>
    <td style="border: 1px solid black;">The x-coordinate of the borrower</td>
  </tr>
  <tr style="border: 1px solid black;" align="center">
    <td style="border: 1px solid black;">ycor</td>
    <td style="border: 1px solid black;">Integer; static</td>
    <td style="border: 1px solid black;">No unit</td>
    <td style="border: 1px solid black;">Any in environment</td>
    <td style="border: 1px solid black;">The y-coordinate of the borrower</td
  </tr>
  <tr style="border: 1px solid black;" align="center">
    <td style="border: 1px solid black;">credit-score</td>
    <td style="border: 1px solid black;">Real number; static</td>
    <td style="border: 1px solid black;">No unit</td>
    <td style="border: 1px solid black;">300-850</td>
    <td style="border: 1px solid black;">The creditworthiness of the borrower</td
  </tr>
  <tr style="border: 1px solid black;" align="center">
    <td style="border: 1px solid black;">debt</td>
    <td style="border: 1px solid black;">Real number; static</td>
    <td style="border: 1px solid black;">£ per month</td>
    <td style="border: 1px solid black;"><u>></u> 0</td>
    <td style="border: 1px solid black;">The amount owed by the borrower</td
  </tr>
  <tr style="border: 1px solid black;" align="center">
    <td style="border: 1px solid black;">balance</td>
    <td style="border: 1px solid black;">Real number; static</td>
    <td style="border: 1px solid black;">£ per month</td>
    <td style="border: 1px solid black;"><u>></u> 0</td>
    <td style="border: 1px solid black;">The current amount in the borrower's account</td>
  </tr>
  <tr style="border: 1px solid black;" align="center">
    <td style="border: 1px solid black;">income</td>
    <td style="border: 1px solid black;">Real number; static</td>
    <td style="border: 1px solid black;">£ per month</td>
    <td style="border: 1px solid black;"><u>></u> 5000</td>
    <td style="border: 1px solid black;">The monthly income received by the borrower</td>
  </tr>
  <tr style="border: 1px solid black;" align="center">
    <td style="border: 1px solid black;">debt-duration</td>
    <td style="border: 1px solid black;">Real number; static</td>
    <td style="border: 1px solid black;">year(s)</td>
    <td style="border: 1px solid black;"><u>></u> 0</td>
    <td style="border: 1px solid black;">The time in years needed to pay back the loan</td>
  </tr>
  <tr style="border: 1px solid black;" align="center">
    <td style="border: 1px solid black;">has-defaulted</td>
    <td style="border: 1px solid black;">Boolean</td>
    <td style="border: 1px solid black;">No unit</td>
    <td style="border: 1px solid black;">true or false</td>
    <td style="border: 1px solid black;">Indicates whether a borrower has defaulted or not</td>
  </tr>
  <tr style="border: 1px solid black;" align="center">
    <td style="border: 1px solid black;">new-loan-probability</td>
    <td style="border: 1px solid black;">Floating-point number; static</td>
    <td style="border: 1px solid black;">No unit</td>
    <td style="border: 1px solid black;">&ge; 0 and &le; 1</td>
    <td style="border: 1px solid black;">The probability that a borrower will receive a new loan</td>
  </tr>
  <tr style="border: 1px solid black;" align="center">
    <td style="border: 1px solid black;">friendship-probability</td>
    <td style="border: 1px solid black;">Floating-point number</td>
    <td style="border: 1px solid black;">No unit</td>
    <td style="border: 1px solid black;">&ge; 0 and &le; 1</td>
    <td style="border: 1px solid black;">The degree to which a borrower is friends with another borrower</td>
  </tr>
</table>

The environment of the model is described by a grid of 33 x 33 patches with wrapping at its edges. The model time-step is 1 month, and any given simulation runs for 30 years, or until all borrowers default on their debt.

## Process overview and scheduling

The model includes the following actions that are executed in this order each time-step.

***Get_New_Loan***
A borrower can at any time take out a new loan, which increases their debt and their balance. This is dependent on their credit scores.

***Balance_Check***
The income of the borrower gets added to their balance. Every borrower then checks their balance to see if they are able to make their monthly payment. If they have enough money, they pay their monthly payment. In case they don't, they get a second chance to ask their friends for money and the duration of the loan is extended, but their credit score decreases. If their friends agree to lend them money, they pay off their debts. Otherwise, credit score decreases, and they default on their debts. 

***Output***
The View, plots and output file are updated.

## Design concepts

*Basic principles*: The basic idea of this model is to explore how agents make decisions regarding loan payments given the variables we previously discussed. Additionally, basic financial concepts like balances, payments, and credit scores are used to determine when the borrowers default on their debts.

*Emergence*: The model's primary output is the overall rate of defaults. Secondary outputs include the average, minimum, maximum, and standard deviation values of credit scores, balances, debts, and incomes. Additionally, the number of defaulters is included. The outputs emerge as agents make decisions about paying monthly payments or not based on their balances.

*Adaptive Behaviour*: In each time step, the agents choose whether to take a new loan or not, and, based on their balance and debt, whether to pay off their debt, ask a friend for money, or default on their debts.

*Objectives*: The model's primary purpose is to explore the behaviour of the default rate under controlled conditions. By monitoring the default rate of borrowers, and other variables, we can develop an insight into the factors that contribute to credit defaults.

*Prediction*: The borrowers in the model can anticipate whether or not their friends will lend them money or not based on their friendship probability. If they lend them money, they can pay off their debts. Otherwise, they default on their debts.

*Sensing*: The borrowers have access to their balance, debts, incomes, and credit scores and know what monthly amount will be paid. They use this information to make a decision about whether or not they will pay the monthly payment amount.

*Interaction*: The borrowers interact with each other to lend each other money based on their friendship and their willingness to lend money. If a borrower decide to lend money to another borrower, the other borrower can use the money to pay off existing loans. This form of lending is considered independent from the loans they take out, which are assumed to be banks, credit unions... etc.

*Stochasticity*: Most of the state variables for the borrowers are set randomly within their respective ranges. This is to simulate an environment where two or more borrowers very rarely have one or more variables with the same value. This makes the simulation very similar to what happens in the real world.

*Observation*: The View shows the location of each borrower on the landscape. A graph will show the overall rate of defaults. Three other graphs will show the average, maximum, minimum, and standard deviation of the borrowers' balances, credit scores, and debts. The number of defaulters and the number of borrowers who are able to make their payments will also be shown

Learning and Collectives are not part of this model.

## Initialisation

The model always starts with a fixed number of borrowers, where each borrower has randomly assigned credit scores. Generally speaking most borrowers will have friendships with other borrowers, but that is entirely dependent on the friendship-probability value, which is set randomly. Their initial balances are calculated based on their credit scores using the formula balance = 50000 - (credit-score \* 50). No borrower will start with a defaulted state. 

## Input data

This model does not need external data to function. However, a user can specify a number of parameters like the number of borrowers and the annual interest rate before setting up the model.

## Submodels

The main submodel in the model is the go procedure, which is responsible for the behaviour of borrowers at each time step. In the go procedure, the following procedures are called:

***get-new-loan***: Checks whether a borrower should receive a new loan or not based on their lending probability. It is implemented such that all borrowers must obtain a loan if they don't have debts.
***balance-check***: Adds the borrower's income to their balance and determines whether a borrower can afford to make a payment or not. If the borrower is unable to make the payment, the debt duration is extended and they can ask their friends for money, but their credit score decreases. If their friends give them the money, the borrowers can use it to pay off their debts. Otherwise, their credit-scores decrease further, and they become defaulters.

## Related Models

This model is not related to any model in the NetLogo Models Library.

## Credits and References

There are no references for this model.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="low-interest-rate-credit-default-experiment" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>get-default-rate</metric>
    <metric>get-defaulters</metric>
    <metric>mean [balance] of borrowers</metric>
    <metric>mean [credit-score] of borrowers</metric>
    <metric>mean [debt] of borrowers</metric>
    <metric>mean [income] of borrowers</metric>
    <enumeratedValueSet variable="annual-interest-rate">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-borrowers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend-lending-probability">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-loan-amount">
      <value value="25000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="high-interest-rate-credit-default-experiment" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>get-default-rate</metric>
    <metric>get-defaulters</metric>
    <metric>mean [balance] of borrowers</metric>
    <metric>mean [credit-score] of borrowers</metric>
    <metric>mean [debt] of borrowers</metric>
    <metric>mean [income] of borrowers</metric>
    <enumeratedValueSet variable="annual-interest-rate">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-borrowers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend-lending-probability">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-loan-amount">
      <value value="25000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="increased-friend-lending-prob-experiment" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>get-default-rate</metric>
    <metric>get-defaulters</metric>
    <metric>mean [balance] of borrowers</metric>
    <metric>mean [credit-score] of borrowers</metric>
    <metric>mean [debt] of borrowers</metric>
    <metric>mean [income] of borrowers</metric>
    <enumeratedValueSet variable="annual-interest-rate">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-borrowers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friend-lending-probability">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-loan-amount">
      <value value="25000"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
