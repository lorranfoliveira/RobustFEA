from run_generic import run

files1 = ['flower_1-1_1.json',
          'flower_1-025_1.json',
          'flower_1-05_1.json',
          'flower_1-075_1.json',
          'flower_1-1_075.json',
          'flower_1-1_05.json',
          'flower_1-1_025.json']

files2 = ['flower_2-1_1.json',
          'flower_2-025_1.json',
          'flower_2-05_1.json',
          'flower_2-075_1.json',
          'flower_2-1_075.json',
          'flower_2-1_05.json',
          'flower_2-1_025.json']

files = files1 + files2

for file in files:
    run(file)
