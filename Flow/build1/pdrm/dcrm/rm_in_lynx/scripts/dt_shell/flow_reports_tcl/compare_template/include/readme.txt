Resource Compare Report
The overall structure of this report is:
(1) index.html.  This is the main report page.
(2) include directory. This directory contains active components of the
    report system (javascript libraries, stylesheets, etc).
(3) data directory.  This directory contains config files and tables
    for comparison.

This report allows the user to visually compare similar sets of data. Each
of the data sets is stored in a single file in the data directory.  The
data files follow a simple pipe-separated format similar to the
lynx_dt output.  Here is a sample file:
HEADER|A|B|C
r1|1|2|3
r2|4|5|6
r3|7|8|9

From this file, note that the columns are named A, B, and C, and the
rows are named r1, r2 and r3.

The data directory also contains a file called tbl.cfg, which lists all
the data files to select from for comparison.  This file is required.
Any files in the data directory that are not listed in the tbl.cfg file
will not be selectable for display.

The data directory can also include a file called format.cfg.  This file
is optional.  It contains data in three categories.

Initial row names to display.
This is a list of row names expected to be found in the data files.
This is an example:
ROWS|r1|r3
These are default values only, and the user can select other rows to display
when the report is displayed.
If no rows are specified in format.cfg, all rows are shown initially.

Initial column names to display.
This is a list of column names expected to be found in the data files.
This is an example:
HEADER|A|B
These are default values only, and the user can select other columns to display
when the report is displayed.
If no columns are specified in format.cfg, all columns are shown initially.

Coloring rules.
One of the features of the Resource Compare report is the ability to color
the background of cells in the tables to quickly identify problems.

A coloring rule starts with FORMAT, and has 6 components:
FORMAT|metric name|light_pct|medium_pct|dark_pct|abs_threshold|improves

metric name: The name of the column that the rule applies to.  In our
example, this would be A, B or C. Extra coloring rules, those that are in
format.cfg, but that reference columns that are not in the data, are harmless
and therefore ignored.

light_pct: The amount of percent change from the reference that triggers
a light color change.  A typical value would be 0.5 (a half percent).

medium_pct: The amount of percent change from the reference that triggers
a medium color change. A typical value would be 2.

dark_pct: The amount of percent change from the reference that triggers
a dark color change. A typical value would be 10.

abs_threshold: If a value is known to change a small amount over time, but
this amount is not all that important, an abs_threshold can be set. If the
absolute value change is less than or equal to this amount, but more than 0,
the value is shown in light gray. Note that this value is not a percentage,
but an absolute value. You can set the abs_threshold to 0 to turn this
feature off.

improves: Can be larger or smaller.  If a value being smaller than the
reference is good, use the word smaller here, and larger otherwise.

With this description of coloring rules, the following rule should make
sense to you:
FORMAT|WNS|0.5|2|10|0.0001|larger
So thinking about WNS values between two tables:
If the new value's delta from the reference is less than or equal to0.0001,
the new value is grayed out, and no other coloring is considered.
If the new value is less than 0.5% higher or lower than the reference value,
no background color is applied.
If the new value is 0.5% higher than the reference, background is light green.
If the new value is 0.5% lower than the reference, background is light red.
If the new value is 2% higher/lower, background is medium green/red.
If the new value is 10% higher/lower, background is dark green/red.

As a convenience, if you have multiple coloring rules with the same values,
you can cut the repetition by declaring a coloring rule and referring to it
elsewhere.  So if many of your metrics behave like WNS, consider this:
RULE|STD_RULE|0.5|2|10|0.0001|larger
FORMAT|WNS|STD_RULE
FORMAT|TNS|STD_RULE

Now WNS and TNS will color the same, and you only have to change the STD_RULE
to have the same change take affect on both columns.

One other convenience is the ability to set coloring rule variables in one place:
VARIABLE|light_pct|0.5
VARIABLE|medium_pct|2.0
VARIABLE|dark_pct|10.0
VARIABLE|abs_threshold|0.0001
Now you can create rules and just leave out variables:
RULE|STD_RULE_L|||||larger
or
FORMAT|WNS|||||larger
This is the same as saying
RULE|STD_RULE_L|0.5|2|10|0.0001|larger
or
FORMAT|WNS|0.5|2|10|0.0001|larger
Also, having these variables named in advance means you only have to change
them in one place to change the coloring rule behavior in your entire report.
Note that these variables are not an all-or-nothing feature.  You can set
only the variables that you feel you need to pre-define.
