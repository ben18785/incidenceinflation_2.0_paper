// The simpler form of stan/nowcast.stan (its first form): lambda a random
// walk, the report effects independent, the additions NB2. It samples more
// cleanly and did as well when fitted to 30 September.
//
// A data-driven nowcast of counts by onset day from the reporting triangle
// (R/nowcast.R). The new count of onset day t between consecutive reports
// is the additions less the removals in that interval:
//   n = A - W,  A ~ NB(mu_a, phi),  W ~ Poisson(rho * mu_a),
//   mu_a = lambda_t * (share of the delay distribution p_t in the interval)
//          * exp(u_report),
// where lambda_t is the expected count of onset day t, and
//   p_t = softmax over delays d = 0..D of g(d) + h(t, d)
// is its delay distribution: g the average shape and h how it changes over
// onset time, both B-splines in log(d + 1) (and in t for h; the few basis
// functions in log delay keep h smooth over delay). The coefficients of h
// are a random walk over the knots in onset time, so the latest pattern is
// carried forward where there are no data. u is an effect of each report.
// The random walks and the report effects are non-centred.
functions {
  // log-probability of a new count n which is NB additions less Poisson
  // removals, the removals summed out up to w_max
  real nb_minus_poisson_lpmf(int n, real log_mu_a, real phi, real mu_w, int w_max) {
    int w0 = n < 0 ? -n : 0;
    if (w0 > w_max)
      return negative_infinity();
    vector[w_max - w0 + 1] terms;
    for (w in w0:w_max)
      terms[w - w0 + 1] = neg_binomial_2_log_lpmf(n + w | log_mu_a, phi) +
                          poisson_lpmf(w | mu_w);
    return log_sum_exp(terms);
  }
}
data {
  int<lower=1> T;                      // onset days
  int<lower=1> D;                      // longest delay, in days
  int<lower=2> Kt;                     // basis functions in onset time
  int<lower=3> Kd;                     // basis functions in log delay
  matrix[T, Kt] Bt;
  matrix[D + 1, Kd] Bd;
  int<lower=1> R;                      // reports
  int<lower=0> N;                      // new counts
  array[N] int<lower=1, upper=T> t;
  array[N] int<lower=0, upper=D> lo;   // first delay of the interval
  array[N] int<lower=0, upper=D> hi;   // last delay of the interval
  array[N] int<lower=1, upper=R> r;
  array[N] int n;                      // may be negative
  // the most removals summed out for each new count: enough for any
  // removal rate up to about a tenth (set in R/nowcast.R)
  array[N] int<lower=0> w_max;
  // for the projections: the count in the last report of each onset day,
  // its delay then, and the day to which counts are projected
  array[T] int count_last;
  array[T] int<lower=0, upper=D> delay_last;
  int<lower=0> day_target;             // as an onset day; 0 for no projection
  // prior scales
  real<lower=0> sigma_lambda_scale;
  real<lower=0> tau_t_scale;
  real<lower=0> sigma_u_scale;
  real<lower=0> rho_scale;
}
parameters {
  real log_lambda_1;
  vector[T - 1] z_lambda;
  real<lower=0> sigma_lambda;
  vector[Kd - 1] beta_g_free;          // the first is held at 0 (softmax)
  matrix[Kt, Kd - 1] z_h;              // the first column of h is held at 0
  real<lower=0> tau_t;
  vector[R] z_u;
  real<lower=0> sigma_u;
  real<lower=0> inv_sqrt_phi;
  real<lower=0> rho;
}
transformed parameters {
  real phi = 1 / square(inv_sqrt_phi);
  vector[T] log_lambda = log_lambda_1 +
    append_row(0, cumulative_sum(sigma_lambda * z_lambda));
  vector[R] u = sigma_u * z_u;
  matrix[T, D + 1] log_p;
  {
    // the first knot's coefficients, then steps of sd tau_t
    matrix[Kt, Kd - 1] steps = append_row(z_h[1], tau_t * z_h[2:Kt]);
    matrix[Kt, Kd - 1] cum = steps;
    for (k in 2:Kt)
      cum[k] = cum[k - 1] + steps[k];
    matrix[Kt, Kd] beta_h = append_col(rep_vector(0, Kt), cum);
    vector[Kd] beta_g = append_row(0, beta_g_free);
    matrix[T, D + 1] eta = rep_matrix((Bd * beta_g)', T) + Bt * beta_h * Bd';
    for (i in 1:T)
      log_p[i] = log_softmax(eta[i]')';
  }
}
model {
  log_lambda_1 ~ normal(log(5), 3);
  z_lambda ~ std_normal();
  sigma_lambda ~ normal(0, sigma_lambda_scale);
  beta_g_free ~ normal(0, 5);
  to_vector(z_h) ~ std_normal();
  tau_t ~ normal(0, tau_t_scale);
  z_u ~ std_normal();
  sigma_u ~ normal(0, sigma_u_scale);
  inv_sqrt_phi ~ normal(0, 1);
  rho ~ normal(0, rho_scale);
  for (i in 1:N) {
    real log_mu_a = log_lambda[t[i]] + log_sum_exp(log_p[t[i], (lo[i] + 1):(hi[i] + 1)]) + u[r[i]];
    n[i] ~ nb_minus_poisson(log_mu_a, phi, rho * exp(log_mu_a), w_max[i]);
  }
}
generated quantities {
  // the count each onset day will show by day_target, if reports are daily
  // from its last report on, and the mean delay of each onset day. A future
  // report's effect is shared by every onset day it counts.
  array[T] int projected;
  vector[T] mean_delay;
  vector[max(day_target, 1)] u_future;
  for (s in 1:max(day_target, 1))
    u_future[s] = normal_rng(0, sigma_u);
  for (i in 1:T) {
    projected[i] = count_last[i];
    if (day_target > 0) {
      int d_end = min(D, day_target - i);
      for (d in (delay_last[i] + 1):d_end) {
        real log_mu_a = log_lambda[i] + log_p[i, d + 1] + u_future[i + d];
        if (log_mu_a > -20) {
          real mu_a = exp(log_mu_a);
          projected[i] += neg_binomial_2_rng(mu_a, phi) - poisson_rng(rho * mu_a);
        }
      }
    }
    mean_delay[i] = dot_product(exp(log_p[i]), linspaced_vector(D + 1, 0, D));
  }
}
