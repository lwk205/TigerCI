/*
 *                This source code is part of
 *
 *                     E  R  K  A  L  E
 *                             -
 *                       DFT from Hel
 *
 * Written by Susi Lehtola, 2010-2012
 * Copyright (c) 2010-2012, Susi Lehtola
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 */


/**
 * \class DensityFit
 *
 * \brief Density fitting / RI routines
 *
 * This class contains density fitting and resolution of the identity
 * routines used for the approximate calculation of the Coulomb and
 * exchange operators J and K.
 *
 * The RI-JK implementation is based on the procedure described in
 *
 * F. Weigend, "A fully direct RI-HF algorithm: Implementation,
 * optimised auxiliary basis sets, demonstration of accuracy and
 * efficiency", Phys. Chem. Chem. Phys. 4, 4285 (2002).
 *
 *
 * If only RI-J is necessary, then the procedure described in
 *
 * K. Eichkorn, O. Treutler, H. Öhm, M. Häser and R. Ahlrichs,
 * "Auxiliary basis sets to approximate Coulomb potentials",
 * Chem. Phys. Lett. 240 (1995), 283-290.
 *
 * is used.
 *
 * \author Susi Lehtola
 * \date 2012/08/22 23:53
 */




#ifndef ERKALE_DENSITYFIT
#define ERKALE_DENSITYFIT

#include "global.h"
#include "basis.h"

/// Density fitting routines
class DensityFit {
  /// Amount of orbital basis functions
  size_t Nbf;
  /// Amount of auxiliary basis functions
  size_t Naux;
  /// Direct calculation? (Compute three-center integrals on-the-fly)
  bool direct;
  /// Hartree-Fock calculation?
  bool hf;

  /// Amount of nuclei
  size_t Nnuc;
  /// Maximum angular momentum
  int maxam;
  /// Maximum contractions
  int maxcontr;

  /// Orbital shells
  std::vector<GaussianShell> orbshells;
  int maxorbam;
  size_t maxorbcontr;
  /// Density fitting shells
  std::vector<GaussianShell> auxshells;
  int maxauxam;
  size_t maxauxcontr;
  /// Dummy shell
  GaussianShell dummy;

  /// Index of dummy function
  size_t dummyind;

  /// List of unique orbital shell pairs
  std::vector<eripair_t> orbpairs;

  /// Index helper
  std::vector<size_t> iidx;

  /// Integrals \f$ ( \alpha | \mu \nu) \f$
  arma::mat a_munu;

  /// \f$ ( \alpha | \beta) \f$
  arma::mat ab;
  /// \f$ ( \alpha | \beta)^-1 \f$
  arma::mat ab_inv;

  /// Form screening matrix
  void form_screening();

 protected:
  /// \f$ ( \alpha | \beta)^-1/2 \f$
  arma::mat ab_invh;

 public:
  /// Constructor
  DensityFit();
  /// Destructor
  ~DensityFit();

  /**
   * Compute integrals, use given linear dependency threshold. The HF
   * flag here controls formation of (a|b)^{-1/2} and (a|b)^{-1}; the
   * HF routine should be more tolerant of linear dependencies in the basis.
   * Returns amount of significant orbital shell pairs.
   */
  size_t fill(const BasisSet & orbbas, const BasisSet & auxbas, bool direct, double erithr, double linthr, bool hf=false);
  /// Compute index in integral table
  size_t idx(size_t imu, size_t inu) const;

  /// Compute estimate of necessary memory
  size_t memory_estimate(const BasisSet & orbbas, const BasisSet & auxbas, bool direct) const;

  /// Compute expansion coefficients c
  arma::vec compute_expansion(const arma::mat & P) const;
  /// Compute expansion coefficients c
  std::vector<arma::vec> compute_expansion(const std::vector<arma::mat> & P) const;

  /// Get Coulomb matrix from P
  arma::mat calcJ(const arma::mat & P) const;
  /// Get Coulomb matrix from P
  std::vector<arma::mat> calcJ(const std::vector<arma::mat> & P) const;

  /// Calculate force from P
  arma::vec forceJ(const arma::mat & P);

  /// Get exchange matrix from orbitals with occupation numbers occs
  arma::mat calcK(const arma::mat & C, const std::vector<double> & occs, size_t memlimit) const;
  /// Get exchange matrix from orbitals with occupation numbers occs
  arma::cx_mat calcK(const arma::cx_mat & C, const std::vector<double> & occs, size_t memlimit) const;

  /// Get the number of orbital functions
  size_t get_Norb() const;
  /// Get the number of auxiliary functions
  size_t get_Naux() const;
  /// Get the three-electron integral
  double get_a_munu(size_t ia, size_t imu, size_t inu) const;
  /// Get ab_inv
  arma::mat get_ab_inv() const;

  /// Get B matrix (must have HF enabled)
  arma::mat B_matrix() const;
};


#endif
