#! /home/b4lldr/miniconda3/envs/bipyt/bin/python

import sys
import pandas as pd
import matplotlib.pyplot as plt


#-----------------------------------------------------------------
filename = sys.argv[1]
print(f'Processing: {filename}')

raw_path   = sys.argv[2]
graph_path = "graphs/graphs-" + ("messages" if sys.argv[3] == "1" else "words")

df_raw = pd.read_csv(f'{raw_path}/{filename}').set_index('datum')

df_raw.index = pd.DatetimeIndex(df_raw.index)

try:
    year_min = df_raw.index[0].year
except:
    print('    ^^ ERROR ^^')
    exit()
year_max = df_raw.index[-1].year
year_diff = year_max - year_min

idx = pd.date_range(f'01 Jan {year_min}', f'01 Jan {year_max + 1}')
df_raw = df_raw.reindex(idx, fill_value=0)


#-----------------------------------------------------------------
# plt style
if year_diff +1 <= 3:
    plt.rcParams['figure.figsize'] = (24, 8)
elif year_diff +1 <= 6:
    plt.rcParams['figure.figsize'] = (24, 16)
else:
    plt.rcParams['figure.figsize'] = (24, 24)

plt.rcParams['font.family'] = 'DejaVu Sans'
plt.style.use('ggplot')

# subplots init
color_bg_all = '#495464'
color_bg_plot = '#222831'
color_text = '#ffffff'

with plt.rc_context({'figure.facecolor':color_bg_all, 'grid.color':color_bg_all, 'axes.edgecolor':color_bg_all,
                        'axes.facecolor':color_bg_plot,
                        'text.color':color_text, 'xtick.color':color_text, 'ytick.color':color_text
                    }): # all the options with rcParams.keys()
    fig, axes = plt.subplots(nrows=year_diff+1, sharex=True, sharey=True)

# subplots for each year
axes_index = 0
for year in range(year_min, year_max + 1):
    tmp = df_raw[ (df_raw.index >= f'{year}-01-01') & (df_raw.index < f'{year + 1}-01-01') ]

    if year_diff:
        ax = axes[axes_index]
        axes_index += 1
    else:
        ax = axes
    tmp.plot(ax=ax, kind='bar', title=f'{year}', legend=False, color='#3dba48').minorticks_off() # dgreen: 3dba48 lgreen: 90de6f red: f05454

# x axis ticks and labels, horizontal spacing
months = ['leden', 'únor', 'březen', 'duben', 'květen', 'červen', 'červenec', 'srpen', 'září', 'říjen', 'listopad', 'prosinec']
ticks = []

for i in range(1, 13):
    ticks.append( df_raw.index.get_loc(f'{year_min}-{str(i).zfill(2)}-01') )

plt.setp(axes, xticks=ticks, xticklabels=months) # plt.xticks(ticks=ticks, labels=months) when only one axis
plt.subplots_adjust(hspace=0.2)

# x labels rotation
plt.xticks(rotation=0)

# save
plt.savefig(f'{graph_path}/{filename}.png', bbox_inches='tight', facecolor=fig.get_facecolor())
