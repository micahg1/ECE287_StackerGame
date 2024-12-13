# **ECE287 FPGA Stacker Game**
By Micah Granadino
## **High-Level Description**
The goal was to create a simple stacker game that works on a field programmable board (FPGA). 
## **Background**
**_Stacker_** is an arcade game that challenges players to stack moving blocks in a straight line to build a tower and reach the top of the screen. The game consists of a vertical display grid and a moving platform of blocks that players attempt to align perfectly as it moves horizontally across the screen. As the player progresses, the blocks move faster, increasing the challenge of precise timing. The game ends if no blocks remain after a failed alignment.
## **Design Description**
To implement this game, a finite state machine (FSM) was designed to manage three main groups of states: moving blocks to the right, moving blocks to the left, and stopping the blocks on the current row.

The first two groups handle the animation of blocks, shifting them based on the 16-bit value assigned to the `curr_row` variable, (e.g.,  `curr_row <= 16'b0000001111000000`). The number of blocks on each row (16-bits in this case) corresponds to the 16 by 12 grid size set by `VIRTUAL_PIXEL_WIDTH` and `VIRTUAL_PIXEL_HEIGHT`. 
The FSM operates through a sequence of states: `WAIT`, `SHIFT`, `RPT` (repeat), `DRAW`, and `END`.

A counter determines the number of repetitions in the `RPT` state before transitioning to `SHIFT`, where the bits in `curr_row` shift either right or left. Blocks are displayed on the screen based on their positions based on the virtual pixel index. If the most significant bit (MSB) or least significant bit (LSB) of curr_row is 1, the direction reverses. The `SHIFT` state concludes when the player presses a button.

Pressing the button moves the FSM to a row processing state group responsible for game logic. This compares the current row with the previous row using a bitwise `&` operator to determine overlapping bits. Remaining overlapping blocks are set to the current row, and the game continues. If no overlapping blocks remain, the game ends with a losing indication of the light on the board. Reaching the top of the screen with a sufficient number of blocks results in a winning condition, signaled by a different light.
## **Presentation of Results**
[Demonstration Link](https://youtu.be/UHpSS0TTxUQ)

[Presentation Link](https://docs.google.com/presentation/d/1d4UEsHCM6q2W1maMhoL606Iej-_W8gWb70ldDW4stCY/edit?usp=sharing)

![image](https://github.com/user-attachments/assets/0d975426-5fe0-4ac9-91e2-fb5e0891ec8f)
## **Conclusion**
The Simple Stacker Game was successfully created on the FPGA. In the span of a few weeks, I was able to implement and complete the final project using skills and resources gained from the ECE287 labs.
## **Citations**
* Used Prof. Jamieson's [VGA_ON_DE1_SOC_2024.zip](https://miamioh.instructure.com/files/33479708/download?download_frd=1) given from the course module
