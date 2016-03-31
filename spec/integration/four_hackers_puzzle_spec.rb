describe "Four Hackers Puzzle" do
  it do
    expect("four_hackers_puzzle").to have_output <<EOF
0-alias = Lennard
0-amount = 160000
0-country = Norway
0-language = Perl
0-name = Frogger
1-alias = Badger
1-amount = 80000
1-country = Belgium
1-language = Lisp
1-name = Dragonene
2-alias = Griffin
2-amount = 10000
2-country = Yemen
2-language = Java
2-name = Phineus
3-alias = Monks
3-amount = 640000
3-country = England
3-language = C
3-name = Armand
EOF
  end
end
