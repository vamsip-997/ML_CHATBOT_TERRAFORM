💞 1️⃣ for loop Example — “I Love You 5 Times”
#!/bin/bash
initializing     condition      incrementing condition/decrementing condition
i=0  0<5                  i=1 to 5               i=i+1 (or) ((i++))


for i in {1..5}
do
  echo "($i) I love you ❤️"
done

💡 Explanation:


{1..5} → 1 nundi 5 varaku loop run avutundi.


Each round lo echo “I love you” print chestundi.


👉 Output:
(1) I love you ❤️
(2) I love you ❤️
(3) I love you ❤️
(4) I love you ❤️
(5) I love you ❤️


💗 2️⃣ while loop Example — “I Love You 5 Times”
#!/bin/bash

i=1
while [ $i -le 5 ]
do
  echo "($i) I love you so much 💕"
  ((i++))
done

💡 Explanation:


i=1 → starting count


[ $i -le 5 ] → condition true until i ≤ 5


((i++)) → count increases by 1 every loop


So until 5, it keeps saying “I love you so much 💕”.


👉 Output:
(1) I love you so much 💕
(2) I love you so much 💕
(3) I love you so much 💕
(4) I love you so much 💕
(5) I love you so much 💕


💘 3️⃣ until loop Example — “I Love You Until 5 Times”
#!/bin/bash

i=1
until [ $i -gt 5 ]
do
  echo "($i) I love you forever 💖"
  ((i++))
done

💡 Explanation:


until → opposite of while


This loop runs until condition becomes true (i > 5)


So, until i = 6, it keeps running.


👉 Output:
(1) I love you forever 💖
(2) I love you forever 💖
(3) I love you forever 💖
(4) I love you forever 💖
(5) I love you forever 💖


🧠 Summary Table
Loop TypeMeaning (Telugu Explanation)Runs While / UntilOutput Meaningfor loopNuvvu 1 nundi 5 varaku “I love you” chepthavFixed range5 times “I love you ❤️”while loopCondition true ayye varaku “I love you” chepthavWhile true5 times “I love you so much 💕”until loopCondition false unte varaku “I love you” chepthavUntil true5 times “I love you forever 💖”

💬 Real-Time Feel Example
Imagine this:
#!/bin/bash

for i in {1..3}
do
  echo "($i) I love you 😍"
  sleep 1
done
echo "End of loop — but not end of love 😄"

🕐 Output with small delay:
(1) I love you 😍
(2) I love you 😍
(3) I love you 😍
End of loop — but not end of love 😄


Want me to show next version where it asks your crush’s name and loops with "I love you <name>" dynamically? 😅