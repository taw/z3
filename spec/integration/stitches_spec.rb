describe "Stitches" do
  it do
    expect("stitches").to have_output_no_color <<EOF
      *     *-*
      |
  *   * *-* *-*
  |
* *   *       *
|     |       |
* * * *   *   *
  | |     |
* * * *-* * *-*
|
* *           * *
  |           | |
  * * *       * * *
    | |           |
* * * *   * *-*   *
| |       |
* * * *   *
    | |
    * *
EOF
  end
end
