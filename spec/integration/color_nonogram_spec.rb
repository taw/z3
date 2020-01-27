describe "Color Nonogram" do
  let(:ascii_board) do <<EOF
3 3 3 3 3 3 3 3 3 3
3 0 2 2 0 0 0 0 0 3
3 0 0 0 0 0 0 0 0 3
3 2 1 0 0 0 2 1 0 3
3 3 3 0 0 0 1 1 0 0
3 0 0 0 0 0 0 0 0 0
0 2 2 1 2 2 2 2 0 3
0 0 2 2 2 2 2 0 0 3
3 0 0 0 0 0 0 0 0 3
3 0 0 3 3 3 3 0 0 3
EOF
  end

  it do
    color_board = ascii_board.gsub(/\d/) do |i|
      {
        "0" => "\e[38;2;255;0;0m0\e[0m",
        "1" => "\e[38;2;0;0;0m1\e[0m",
        "2" => "\e[38;2;255;255;255m2\e[0m",
        "3" => "\e[38;2;165;42;42m3\e[0m",
      }[i]
    end

    expect("color_nonogram").to have_output color_board
  end
end
