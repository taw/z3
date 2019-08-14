describe "Dominosa" do
  it do
    expect("dominosa").to have_output <<EOF
5*5 7 4*1 1 4 2 3
    *     * * * *
2*0 2 4*7 5 4 2 0

4*0 0 3 2 0 3 4*5
    * * * * *
1*1 6 4 6 5 2 5 6
              * *
6 1 1 7*7 5 6 3 6
* * *     * *
7 3 0 2*4 2 1 6*3

6 5*6 0 1 3*3 0*0
*     * *
4 5*7 7 7 2*1 7*3
EOF
  end
end
