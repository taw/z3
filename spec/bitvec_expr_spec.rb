describe Z3::BitvecExpr do
  let(:a) { Z3::Bitvec("a", 8) }
  let(:b) { Z3::Bitvec("b", 8) }
  let(:c) { Z3::Bitvec("c", 8) }
  let(:x) { Z3::Bool("x") }

  it "==" do
    expect([a == 2, b == -254, x == (a == b)]).to have_solution(x => true)
    expect([a == 2, b == 2, x == (a == b)]).to have_solution(x => true)
    expect([a == 2, b == 3, x == (a == b)]).to have_solution(x => false)
  end

  it "!=" do
    expect([a == 2, b == -254, x == (a != b)]).to have_solution(x => false)
    expect([a == 2, b == 2, x == (a != b)]).to have_solution(x => false)
    expect([a == 2, b == 3, x == (a != b)]).to have_solution(x => true)
  end

  it "+" do
    expect([a == 2, b == 40, c == (a + b)]).to have_solution(c => 42)
    expect([a == 200, b == 40, c == (a + b)]).to have_solution(c => 240)
    expect([a == -1, b == -1, c == (a + b)]).to have_solution(c => 254)
  end

  it "-" do
    expect([a == 50, b == 8, c == (a - b)]).to have_solution(c => 42)
    expect([a == 200, b == 40, c == (a - b)]).to have_solution(c => 160)
    expect([a == 40, b == 200, c == (a - b)]).to have_solution(c => 96)
  end

  it "*" do
    expect([a == 3, b == 40, c == (a * b)]).to have_solution(c => 120)
    expect([a == 30, b == 42, c == (a * b)]).to have_solution(c => 236)
  end

  it "&" do
    expect([a == 50, b == 27, c == (a & b)]).to have_solution(c => 18)
  end

  it "|" do
    expect([a == 50, b == 27, c == (a | b)]).to have_solution(c => 59)
  end

  it "^" do
    expect([a == 50, b == 27, c == (a ^ b)]).to have_solution(c => 41)
  end

  it "unary -" do
    expect([a == 50, b == -a]).to have_solution(b => 206)
  end

  it "~" do
    expect([a == 50, b == ~a]).to have_solution(b => 205)
  end

  it ">" do
    expect{ a > b }.to raise_error(Z3::Exception)
    expect([a == 100, b ==  20, x == a.unsigned_gt(b)]).to have_solution(x => true)
    expect([a == 100, b == 100, x == a.unsigned_gt(b)]).to have_solution(x => false)
    expect([a == 100, b == 120, x == a.unsigned_gt(b)]).to have_solution(x => false)
    expect([a == 100, b == 200, x == a.unsigned_gt(b)]).to have_solution(x => false)
    expect([a == 100, b ==  20, x == a.signed_gt(b)]).to have_solution(x => true)
    expect([a == 100, b == 100, x == a.signed_gt(b)]).to have_solution(x => false)
    expect([a == 100, b == 120, x == a.signed_gt(b)]).to have_solution(x => false)
    expect([a == 100, b == 200, x == a.signed_gt(b)]).to have_solution(x => true)
  end

  it ">=" do
    expect{ a >= b }.to raise_error(Z3::Exception)
    expect([a == 100, b ==  20, x == a.unsigned_ge(b)]).to have_solution(x => true)
    expect([a == 100, b == 100, x == a.unsigned_ge(b)]).to have_solution(x => true)
    expect([a == 100, b == 120, x == a.unsigned_ge(b)]).to have_solution(x => false)
    expect([a == 100, b == 200, x == a.unsigned_ge(b)]).to have_solution(x => false)
    expect([a == 100, b ==  20, x == a.signed_ge(b)]).to have_solution(x => true)
    expect([a == 100, b == 100, x == a.signed_ge(b)]).to have_solution(x => true)
    expect([a == 100, b == 120, x == a.signed_ge(b)]).to have_solution(x => false)
    expect([a == 100, b == 200, x == a.signed_ge(b)]).to have_solution(x => true)
  end

  it "<" do
    expect{ a < b }.to raise_error(Z3::Exception)
    expect([a == 100, b ==  20, x == a.unsigned_lt(b)]).to have_solution(x => false)
    expect([a == 100, b == 100, x == a.unsigned_lt(b)]).to have_solution(x => false)
    expect([a == 100, b == 120, x == a.unsigned_lt(b)]).to have_solution(x =>  true)
    expect([a == 100, b == 200, x == a.unsigned_lt(b)]).to have_solution(x =>  true)
    expect([a == 100, b ==  20, x == a.signed_lt(b)]).to have_solution(x => false)
    expect([a == 100, b == 100, x == a.signed_lt(b)]).to have_solution(x => false)
    expect([a == 100, b == 120, x == a.signed_lt(b)]).to have_solution(x =>  true)
    expect([a == 100, b == 200, x == a.signed_lt(b)]).to have_solution(x => false)
  end

  it "<=" do
    expect{ a <= b }.to raise_error(Z3::Exception)
    expect([a == 100, b ==  20, x == a.unsigned_le(b)]).to have_solution(x => false)
    expect([a == 100, b == 100, x == a.unsigned_le(b)]).to have_solution(x =>  true)
    expect([a == 100, b == 120, x == a.unsigned_le(b)]).to have_solution(x =>  true)
    expect([a == 100, b == 200, x == a.unsigned_le(b)]).to have_solution(x =>  true)
    expect([a == 100, b ==  20, x == a.signed_le(b)]).to have_solution(x => false)
    expect([a == 100, b == 100, x == a.signed_le(b)]).to have_solution(x =>  true)
    expect([a == 100, b == 120, x == a.signed_le(b)]).to have_solution(x =>  true)
    expect([a == 100, b == 200, x == a.signed_le(b)]).to have_solution(x => false)
  end
end
