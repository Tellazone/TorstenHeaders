#ifndef STAN_MATH_REV_MAT_FUNCTOR_ALGEBRA_SOLVER_HPP
#define STAN_MATH_REV_MAT_FUNCTOR_ALGEBRA_SOLVER_HPP

#include <stan/math/rev/mat/functor/algebra_system.hpp>
#include <stan/math/prim/mat/fun/mdivide_left.hpp>
#include <stan/math/rev/core.hpp>
#include <stan/math/rev/scal/meta/is_var.hpp>
#include <stan/math/prim/scal/err/check_finite.hpp>
#include <stan/math/prim/scal/err/check_consistent_size.hpp>
#include <stan/math/prim/arr/err/check_nonzero_size.hpp>
#include <unsupported/Eigen/NonLinearOptimization>
#include <iostream>
#include <string>
#include <vector>

namespace stan {
  namespace math {

    /**
     * The vari class for the algebraic solver. We compute the  Jacobian of
     * the solutions with respect to the parameters using the implicit
     * function theorem. The call to Jacobian() occurs outside the call to
     * chain() -- this prevents malloc issues.
     *
     * Members:
     * y_ the vector of parameters
     * y_size_ the number of parameters
     * x_size_ the number of unknowns
     * theta_ the vector of solution
     * Jx_y_ the Jacobian of the solution with respect to the parameters.
     */
    template <typename FS, typename F, typename T, typename FX>
    struct algebra_solver_vari : public vari {
      vari** y_;
      int y_size_;
      int x_size_;
      vari** theta_;
      Eigen::MatrixXd Jx_y_;

      algebra_solver_vari(const FS& fs,
                          const F& f,
                          const Eigen::VectorXd x,
                          const Eigen::Matrix<T, Eigen::Dynamic, 1> y,
                          const std::vector<double> dat,
                          const std::vector<int> dat_int,
                          const Eigen::VectorXd theta_dbl,
                          FX& fx,
                          std::ostream* msgs)
        : vari(theta_dbl(0)),
          y_(ChainableStack::memalloc_.alloc_array<vari*>(y.size())),
          y_size_(y.size()),
          x_size_(x.size()),
          theta_(ChainableStack::memalloc_.alloc_array<vari*>(x.size())) {
        for (int i = 0; i < y.size(); ++i)
          y_[i] = y(i).vi_;

        theta_[0] = this;
        for (int i = 1; i < x.size(); ++i)
          theta_[i] = new vari(theta_dbl(i), false);

        // Compute the Jacobian
        Eigen::MatrixXd Jf_x = fx.get_jacobian(theta_dbl);
        hybrj_functor_solver<FS, F, double, double>
          fy(fs, f, theta_dbl, value_of(y), dat, dat_int, msgs, false);
        Eigen::MatrixXd Jf_y = fy.get_jacobian(value_of(y));

        Jx_y_ = - stan::math::mdivide_left(Jf_x, Jf_y);
      }

      void chain() {
        for (int i = 0; i < x_size_; i++)
          for (int j = 0; j < y_size_; j++)
            y_[j]->adj_ += theta_[i]->adj_ * Jx_y_(i, j);
      }
    };

    /**
     * Return the solution to the specified system of algebraic
     * equations given an initial guess, and parameters and data,
     * which get passed into the algebraic system. The user can
     * also specify the relative tolerance (xtol in Eigen's code),
     * the function tolerance, and the maximum number of steps
     * (maxfev in Eigen's code).
     *
     * Throw an exception if the norm of f(x), where f is the
     * output of the algebraic system and x the proposed solution,
     * is greater than the function tolerance. We here use the
     * norm as a metric to measure how far we are from 0.
     *
     * @tparam F type of equation system function.
     * @param[in] f Functor that evaluates the system of equations.
     * @param[in] x Vector of starting values.
     * @param[in] y parameter vector for the equation system. The function
     *            is overloaded to treat y as a vector of doubles or of a
     *            a template type T.
     * @param[in] dat continuous data vector for the equation system.
     * @param[in] dat_int integer data vector for the equation system.
     * @param[in, out] msgs the print stream for warning messages.
     * @param[in] relative_tolerance determines the convergence criteria
     *            for the solution.
     * @param[in] function_tolerance determines whether roots are acceptable.
     * @param[in] max_num_steps  maximum number of function evaluations.
     * @return theta Vector of solutions to the system of equations.
     */
    template <typename F>
    Eigen::VectorXd
    algebra_solver(const F& f,
                   const Eigen::VectorXd& x,
                   const Eigen::VectorXd& y,
                   const std::vector<double>& dat,
                   const std::vector<int>& dat_int,
                   std::ostream* msgs = 0,
                   double relative_tolerance = 1e-10,
                   double function_tolerance = 1e-6,
                   long int max_num_steps = 1e+3) {  // NOLINT(runtime/int)
      // Check that arguments are valid
      check_nonzero_size("algebra_solver", "initial guess", x);
      check_nonzero_size("algebra_solver", "parameter vector", y);
      for (int i = 0; i < x.size(); i++)  // FIX ME - do these w/o for loop?
        check_finite("algebra_solver", "initial guess", x(i));
      for (int i = 0; i < y.size(); i++)
        check_finite("algebra_solver", "parameter vector", y(i));
      for (size_t i = 0; i < dat.size(); i++)
        check_finite("algebra_solver", "continuous data", dat[i]);

      if (relative_tolerance <= 0)
        invalid_argument("algebra_solver",
                         "relative_tolerance,", relative_tolerance,
                         "", ", must be greater than 0");
      if (function_tolerance <= 0)
        invalid_argument("algebra_solver",
                         "function_tolerance,", function_tolerance,
                         "", ", must be greater than 0");
      if (max_num_steps <= 0)
        invalid_argument("algebra_solver",
                         "max_num_steps,", max_num_steps,
                         "", ", must be greater than 0");

      // Create functor for algebraic system
      typedef system_functor<F, double, double> FS;
      typedef hybrj_functor_solver<FS, F, double, double> FX;
      FX fx(FS(), f, x, y, dat, dat_int, msgs, true);
      Eigen::HybridNonLinearSolver<FX> solver(fx);

      // Check dimension unknowns equals dimension of system output
      int z_size = fx.get_value(x).size();  // FIX ME: do w/o computing fx?
      if (z_size != x.size()) {
        std::stringstream msg;
        msg << ", but should have the same dimension as x "
            << "(the vector of unknowns), which is: "
            << x.size();
        std::string msg_str(msg.str());
        invalid_argument("algebra_solver", "the ouput of the algebraic system",
                         z_size, "has dimension = ", msg_str.c_str());
      }

      // Compute theta_dbl
      Eigen::VectorXd theta_dbl = x;
      solver.parameters.xtol = relative_tolerance;
      solver.parameters.maxfev = max_num_steps;
      solver.solve(theta_dbl);

      // Check if the max number of steps has been exceeded
      if (solver.nfev >= max_num_steps)
        invalid_argument("algebra_solver", "max number of iterations:",
                         max_num_steps, "", " exceeded.");

      // Check solution is a root
      Eigen::VectorXd system = fx.get_value(theta_dbl);
      if (system.stableNorm() > function_tolerance) {
          std::stringstream msg_index;
          std::stringstream msg_f;
          msg_f << " but should be lower than the function tolerance: "
                << function_tolerance
                << ". Consider increasing the relative tolerance and the"
                << " max_num_steps.";
          std::string msg_str_f(msg_f.str());

          invalid_argument("algebra_solver",
                           "the norm of the algebraic function is:",
                           system.stableNorm(), "", msg_str_f.c_str());
      }

      return theta_dbl;
     }

    /**
     * Overload the algebraic system to handle the case where y
     * is a vector of parameters (var). The overload calls the
     * algebraic solver defined above and builds a vari object on
     * top, using the algebra_solver_vari class.
     *
     *
     * @tparam F type of equation system function.
     * @tparam T  Type of elements in y vectors.
     * @param[in] f Functor that evaluates the system of equations.
     * @param[in] x Vector of starting values.
     * @param[in] y parameter vector for the equation system.
     * @param[in] dat continuous data vector for the equation system.
     * @param[in] dat_int integer data vector for the equation system.
     * @param[in, out] msgs the print stream for warning messages.
     * @param[in] relative_tolerance determines the convergence criteria
     *            for the solution.
     * @param[in] function_tolerance determines whether roots are acceptable.
     * @param[in] max_num_steps  maximum number of function evaluations.
     * @return theta Vector of solutions to the system of equations.
     */
    template <typename F, typename T>
    Eigen::Matrix<T, Eigen::Dynamic, 1>
    algebra_solver(const F& f,
                   const Eigen::VectorXd& x,
                   const Eigen::Matrix<T, Eigen::Dynamic, 1>& y,
                   const std::vector<double>& dat,
                   const std::vector<int>& dat_int,
                   std::ostream* msgs = 0,
                   double relative_tolerance = 1e-10,
                   double function_tolerance = 1e-6,
                   long int max_num_steps = 1e+3) {  // NOLINT(runtime/int)
      Eigen::VectorXd theta_dbl = algebra_solver(f, x, value_of(y), dat,
                                                 dat_int, 0,
                                                 relative_tolerance,
                                                 function_tolerance,
                                                 max_num_steps);

      // FIX ME - the next three lines are redeundant (they occur in the prim
      // algebra solver), but shouldn't be too expensive.
      typedef system_functor<F, double, double> FS;
      typedef hybrj_functor_solver<FS, F, double, double> FX;
      FX fx(FS(), f, x, value_of(y), dat, dat_int, msgs, true);

      // Construct vari
      algebra_solver_vari<FS, F,  T, FX>* vi0
        = new algebra_solver_vari<FS, F, T, FX>(FS(), f, x, y, dat, dat_int,
                                                theta_dbl, fx, msgs);
      Eigen::Matrix<T, Eigen::Dynamic, 1> theta(x.size());
      theta(0) = var(vi0);
      for (int i = 1; i < x.size(); ++i)
        theta(i) = var(vi0->theta_[i]);

      return theta;
    }

  }
}

#endif