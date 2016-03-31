describe "Letter Connections" do
  it "can solve letter connections puzzle" do
    expect("letter_connections_solver").to have_output <<EOF
→k →k *K *J →f →f →f →f *F *E
↑k ↓F →J ↑j ↑f →e →e →e →e ↑e
↑k →f →f →f ↑f ↑e *G ←g ←g ←g
↑k ←K →i *I →e ↑e →b →b ↓b ↑g
→i →i ↑i →e ↑e →b ↑b ↓D ↓b ↑g
↑I →E →e ↑e →b ↑b ↓d ←d *B ↑g
↓h ←h ←h ←H ↑b ↓d ←d *C *D ↑g
↓h →a →a *A ↑b ↓d →C ↑c ↑d ↑g
↓h ↑A →h *H ↑b →d →d →d ↑d ↑g
→h →h ↑h →B ↑b →G →g →g →g ↑g
EOF
  end
end
