; Fixture for Optimize#from_file
(declare-const optimize_from_file_x Int)
(declare-const optimize_from_file_y Int)
(assert (>= optimize_from_file_x 0))
(assert (>= optimize_from_file_y 0))
(assert (= (+ optimize_from_file_x optimize_from_file_y) 10))
(maximize optimize_from_file_x)
