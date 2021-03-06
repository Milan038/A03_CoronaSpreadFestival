; ************************************************
; **********     Agent definition     ************
; ************************************************

; Instead of just using 'turtles', in this model there will be different 'types' of people
; who behave differently. Initially we have a type of person called a 'visitor'

breed [visitors visitor]

visitors-own[
  destination
  previous_destination
  ticks_since_here
  next_to_infectious
  corona?
  infectious?
  vaccinated?
  stayRed
  stayOrange
  stayYellow
  stayBlue
]

globals[
  mask-effectiveness
  vaccin-effectiveness
  entered
  prob
]

; ************************************************
; ************     Go procedures      ************
; ************************************************


; This procedure is called every time the model iterates
to go
  if ticks > 1801 [stop]
  if entered < 100 [
    setup-people
  ]
  set entered entered + 1
  ; Tell the visitors to walk around (call a procedure called 'move')
  ask visitors [
    if ticks > 1800 [infect-new]
    move
    ifelse any? other turtles in-cone 0.75 360 with [infectious?] [
      set next_to_infectious next_to_infectious + 1
    ]
    [
      if next_to_infectious > 0 [
        infect-new
      ]
      set next_to_infectious 0
    ]
    ;if infectious? and ticks_since_here > 0 [infect]
  ]
  update
  tick

end

to update
  ask visitors [
    if corona? and not infectious?[
      set color pink
    ]
    if corona? and infectious? [
      set color red
    ]
  ]
end

to move
  face destination

  ; if at goal
  ;    if long enough, select new goal
  ;    elif spot in front free move forward
  ;    else nothing

  ifelse ticks_since_here > 0
  [
    ifelse ticks - ticks_since_here > ticks-to-stay-on-patch destination
    [
      set ticks_since_here 0
      ; find new destination till it is not the same as previous_destination, color-wise
      while [[pcolor] of previous_destination = [pcolor] of destination]
      [
        set prob random-float 100
        (ifelse prob < 80
        [
          set destination one-of patches with [
            pcolor = red
          ]
        ]
        prob > 80 and prob < 90
        [
          set destination one-of patches with [
            pcolor = yellow
          ]
        ]
        prob > 90 and prob < 95
        [
          set destination one-of patches with [
            pcolor = blue
          ]
        ]
        prob > 95 and prob < 100
        [
          set destination one-of patches with [
            pcolor = orange
          ]
        ])
      ]
      ; if a new destination is set, set it as previous destination for the next time
      set previous_destination destination
    ]
    [
      ; if visitor is not at the front of the destination
      if([pcolor] of patch-ahead 2 != [pcolor] of destination)
      [
        ; check if the visitor is stuck behind someone else
        ifelse (any? other turtles in-cone 1 60)
        [
          let closest-visitor min-one-of other turtles in-cone 1 60 [distance myself]
          ; if yes, change to a random destination (with the same color) if the person in front has the same destination
          if ([pcolor] of destination = [[pcolor] of destination] of closest-visitor)
          [
            ifelse [pcolor] of destination = red or [pcolor] of destination = orange
            [
              ; if changing destination creates a destination to a brown patch, don't switch destination
              if [pcolor] of patch [pxcor] of patch-here [pycor] of destination != brown
              [
                set destination (patch (21 + random 33) [pycor] of destination)
              ]
            ]
            [
              ; if changing destination creates a destination to a brown patch, don't switch destination
              if [pcolor] of patch [pxcor] of destination [pycor] of patch-here != brown
              [
                set destination (patch [pxcor] of destination (28 + random 20))
              ]
            ]
          ]
        ; not stuck behind another visitor, move forward
        ]
        [
          forward 1
        ]
      ]
    ]
  ]

  ; else
  ;    if agent in cone and agent in cone same goal and agent in cone goal
  ;        set at goal
  ;    else keep moving forward
  [
    ifelse any? other turtles in-cone 1 60
    [
      let closest-visitor min-one-of other turtles in-cone 1 60 [distance myself]
      ifelse [pcolor] of destination = [[pcolor] of destination] of closest-visitor and [ticks_since_here] of closest-visitor > 0
      [
        set ticks_since_here ticks
      ]
      [
        forward 1
        if [pcolor] of patch-ahead 2 = [pcolor] of destination
        [
          set ticks_since_here ticks
        ]
      ]
    ]
    [
      forward 1
      if [pcolor] of patch-ahead 2 = [pcolor] of destination
      [
        set ticks_since_here ticks
      ]
    ]
  ]

end

; function returning the correct ticks to stay at certain destination
to-report ticks-to-stay-on-patch [p]
  if [pcolor] of p = red
    [
      report stayRed
    ]
  if [pcolor] of p = orange
    [
      report stayOrange
    ]
  if [pcolor] of p = blue
    [
      report stayBlue
    ]
  if [pcolor] of p = yellow
    [
      report stayYellow
    ]
end

; ************************************************
; ************    Visitor procedures    **********
; ************************************************

to get-corona
  set corona? true
end

;Check if other agents on the same patch have corona, if not check if mask is on/off
;Create a chance that someone gets corona, based on ticks_since_here and infectiousness
to infect
  ask other visitors-here with [not corona?] [
    let infect_probability 10 ^ ((log 101 10) / 90 * next_to_infectious) - 1
    if infect_probability > 1.0 [set infect_probability 1.0]
    ifelse mask [
      ifelse vaccinated? [
        if(random-float 100 < (1 - mask-effectiveness) * infect_probability and random-float 100 < (1 - vaccin-effectiveness))[
          get-corona
        ]
      ]
      [
        if(random-float 100 < (1 - mask-effectiveness) * infect_probability) [
          get-corona
        ]
      ]
    ]
    [
      ifelse vaccinated? [
        if (random-float 100 < infect_probability and random-float 100 < (1 - vaccin-effectiveness))  [
          get-corona
        ]
      ]
      [
        if (random-float 100 < infect_probability) [
          get-corona
        ]
      ]
    ]
  ]
end

to infect-new
  let infect_probability 10 ^ ((log 101 10) / 90 * next_to_infectious) - 1
    if infect_probability > 1.0 [set infect_probability 1.0]
    ifelse mask [
      if random-float 100 < (1 - mask-effectiveness) * infect_probability and vaccinated? = false [
        get-corona
      ]
    ]
    [
      if random-float 100 < infect_probability  and vaccinated? = false [
        get-corona
      ]
    ]
end
; ************************************************
; ************    Setup procedures    ************
; ************************************************


; Procedure to set up the model (called when 'setup' button is pressed)
to setup
  print "Setting up model."
  __clear-all-and-reset-ticks
  setup-patches
  setup-people
  setup-globals
end




; These last procedures create the different stages and food stalls.

to setup-patches
  ; set all patches to brown initially
  ask patches [
    set pcolor brown
  ]

  ; now make the different tents/venues
  make-venues

end

to make-venues
  ; first, make a big stage in the south.
  ; changed x +/- 5 to x +- 20
  ask patches with [ pycor < 4 and pxcor > 20 and pxcor < max-pxcor - 20 ] [
    set pcolor red
  ]

  ; now make the small stage to the north.
  ; changed x +/- 10 to x +- 30
  ask patches with [ pycor > max-pycor - 2 and pxcor > 20 and pxcor < max-pxcor - 20 ] [
    set pcolor orange
  ]

  ; create the food tents.
  ; Don't worry about how this code works, it is basically just finding the patches with
  ; the coordinates that we want to turn into food or beer tents.
  ask patches with [pycor > max-pycor / 2 - 10 and pycor < max-pycor / 2 + 10 and pxcor < 4] [
    set pcolor blue
  ]

  ask patches with [pycor > max-pycor / 2 - 10 and pycor < max-pycor / 2 + 10 and pxcor > max-pxcor - 4] [
    set pcolor yellow
  ]

end

to setup-people
  create-visitors (0.01 * number-of-agents) [
    set size 1.5
    set shape "person"
    set color green
    set size 1.5
    setxy 0 max-pycor
    ;This last bit sets the visitor's 'destination' variable
    set destination one-of patches with [
      pcolor = red
    ]
    set previous_destination destination
    set corona? false
    set infectious? false
    set vaccinated? false
    set stayRed 90 + random 180 ; agent stays at stage between 15-45 minutes
    set stayOrange 60 + random 60 ; agent stays at toilet between 10-20 minutes
    set stayYellow 30 + random 30 ; agent stays at beer stand 5-10 minutes
    set stayBlue 60 + random 30 ; agent stays at food stand 10-15 minutes
    ifelse random-float 100 < %vaccinated [
      set vaccinated? true
      set color blue
    ]
    [
      if random-float 100 < %infected [
        set infectious? true
        set corona? true
        set color red
      ]
    ]
  ]
end

to setup-globals
  set entered 1
  set mask-effectiveness 0.79
  set vaccin-effectiveness 0.90
end
@#$#@#$#@
GRAPHICS-WINDOW
255
11
871
628
-1
-1
8.0
1
10
1
1
1
0
0
0
1
0
75
0
75
1
1
1
ticks
30.0

BUTTON
31
22
131
55
Setup Model
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
32
62
121
95
Run Model
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

SLIDER
14
116
186
149
number-of-agents
number-of-agents
0
2000
500.0
1
1
NIL
HORIZONTAL

SLIDER
14
167
186
200
%infected
%infected
0
100
1.5
0.11
1
NIL
HORIZONTAL

SLIDER
13
225
185
258
%vaccinated
%vaccinated
0
100
0.0
1
1
NIL
HORIZONTAL

SWITCH
34
332
137
365
mask
mask
1
1
-1000

PLOT
25
450
225
600
Infections
Hours
People
0.0
10.0
0.0
7.0
true
true
"" ""
PENS
"Infected" 1.0 0 -2674135 true "" "plot (count visitors with [corona?]) - (count visitors with [infectious?])"

MONITOR
124
401
221
446
Total infected
(count visitors with [corona?]) - (count visitors with [infectious?])
17
1
11

MONITOR
28
400
102
445
% infected
((count visitors with [corona?]) - (count visitors with [infectious?])) / count visitors * 100
17
1
11

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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

sheep 2
false
0
Polygon -7500403 true true 209 183 194 198 179 198 164 183 164 174 149 183 89 183 74 168 59 198 44 198 29 185 43 151 28 121 44 91 59 80 89 80 164 95 194 80 254 65 269 80 284 125 269 140 239 125 224 153 209 168
Rectangle -7500403 true true 180 195 195 225
Rectangle -7500403 true true 45 195 60 225
Rectangle -16777216 true false 180 225 195 240
Rectangle -16777216 true false 45 225 60 240
Polygon -7500403 true true 245 60 250 72 240 78 225 63 230 51
Polygon -7500403 true true 25 72 40 80 42 98 22 91
Line -16777216 false 270 137 251 122
Line -16777216 false 266 90 254 90

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1800"/>
    <metric>count turtles</metric>
    <steppedValueSet variable="number-of-agents" first="500" step="500" last="2000"/>
    <enumeratedValueSet variable="%vaccinated">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mask">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%infected">
      <value value="1.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1800"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="number-of-agents">
      <value value="2000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="%vaccinated" first="0" step="10" last="100"/>
    <enumeratedValueSet variable="mask">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%infected">
      <value value="1.5"/>
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
