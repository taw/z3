describe "Pyramid Nonogram" do
  it do
    expect("pyramid_nonogram").to have_output <<EOF
            △
           ▲▽▲
          △▼△▽△
         ▲▼△▽▲▽▲
        △▼▲▽▲▼△▼△
       ▲▼▲▽△▽△▽▲▼△
      ▲▼△▽△▼▲▽△▼△▼△
     △▼△▽△▽△▽▲▼△▼▲▼▲
    △▼▲▽△▼▲▽▲▽△▽△▽△▽△
   ▲▽△▼▲▼△▽△▼▲▽▲▽▲▽▲▼▲
  △▽△▽△▼▲▽▲▽△▽△▼▲▼△▼△▽△
 ▲▼△▼△▽△▽▲▼▲▼△▽▲▽▲▼▲▽△▼▲
EOF
  end
end
