describe "Kropki" do
  it do
    expect("kropki").to have_output <<EOF
+-+-+-+-+-+-+
|5|1*2|6*3o4|
+-+-+-+*+o+*+
|1|6o5|3o4*2|
+-+-+o+o+-+-+
|3o4|6|2o1|5|
+*+o+-+-+o+-+
|6*3o4o5|2*1|
+-+-+-+o+-+-+
|2|5|1|4|6*3|
+*+-+-+-+o+*+
|4*2o3|1|5o6|
+-+-+-+-+-+-+
EOF
  end
end
