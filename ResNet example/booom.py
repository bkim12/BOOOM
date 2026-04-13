import time
import math
import numpy as np
from typing import Callable, Tuple, Optional


def create_premultiplied_matrix(O: np.ndarray, r_i: int, r_j: int, theta: float) -> np.ndarray:
    """
    Premultiply O by a Givens rotation acting on rows r_i and r_j.

    This matches the MATLAB helper:
        O_updated([r_i,r_j],:) = [term_1 - term_4; term_2 + term_3]

    Parameters
    ----------
    O : np.ndarray, shape (p, d)
        Current orthogonal / column-orthonormal matrix.
    r_i, r_j : int
        Row indices (0-based in Python).
    theta : float
        Rotation angle.

    Returns
    -------
    O_updated : np.ndarray, shape (p, d)
        Updated matrix after premultiplying by the corresponding Givens rotation.
    """
    O_updated = O.copy()

    row_i = O[r_i, :].copy()
    row_j = O[r_j, :].copy()

    term_1 = row_i * math.cos(theta)
    term_2 = row_i * math.sin(theta)

    term_3 = row_j * math.cos(theta)
    term_4 = row_j * math.sin(theta)

    O_updated[r_i, :] = term_1 - term_4
    O_updated[r_j, :] = term_2 + term_3

    return O_updated


def booom(
    obj_fun: Callable[[np.ndarray], float],
    O_initial: np.ndarray,
    MaxTime: float = 3600,
    MaxRuns: int = 1000,
    MaxIter: int = 10000,
    sInitial: float = 1.0,
    rho: float = 2.0,
    TolFun1: float = 1e-6,
    TolFun2: float = 1e-10,
    phi: float = 1e-20,
    DisplayUpdate: int = 1,
    DisplayEvery: float = 2.0,
    PrintStepSize: int = 1,
    PrintSolution: int = 0,
) -> Tuple[np.ndarray, float, float]:
    """
    BOOOM: Black-box optimization over orthogonal / column-orthonormal matrices.

    This is a close Python translation of your MATLAB implementation.

    Parameters
    ----------
    obj_fun : callable
        Objective function to MINIMIZE. Takes O (p x d) and returns scalar float.
    O_initial : np.ndarray
        Initial matrix, shape (p, d). Typically column-orthonormal.
    MaxTime : float
        Maximum allowed runtime in seconds.
    MaxRuns : int
        Maximum number of BOOOM runs.
    MaxIter : int
        Maximum number of iterations per run.
    sInitial : float
        Initial step scale. Actual initial angle is thetaInitial = pi * sInitial.
    rho : float
        Step-size reduction factor.
    TolFun1 : float
        Within-run tolerance for deciding whether to reduce step size.
    TolFun2 : float
        Across-run tolerance for stopping successive runs.
    phi : float
        Minimum allowed step size threshold.
    DisplayUpdate : int
        If 1, print progress updates.
    DisplayEvery : float
        Minimum elapsed seconds between progress prints.
    PrintStepSize : int
        If 1, print log10(theta/pi) in progress messages.
    PrintSolution : int
        If 1, print final solution matrix.

    Returns
    -------
    O_opt : np.ndarray
        Optimized matrix.
    fval : float
        Objective value at O_opt.
    comp_time : float
        Total computation time in seconds.
    """
    # ---------------------------
    # Basic input checks
    # ---------------------------
    O_initial = np.asarray(O_initial, dtype=float)
    if O_initial.ndim != 2:
        raise ValueError("O_initial must be a 2D numpy array.")

    thetaInitial = math.pi * sInitial
    nrows = O_initial.shape[0]

    # Upper-triangular row pairs: all rotation planes (i,j), i<j
    pairs = [(i, j) for i in range(nrows) for j in range(i + 1, nrows)]
    num_rotations = len(pairs)
    total_moves = 2 * num_rotations

    run_soln_array = np.full(MaxRuns, np.nan)
    last_print_time = 0.0
    break_now = False

    print("========================= BOOOM Starts =======================")
    start_time = time.time()

    O_updated = O_initial.copy()
    CurrentValue = obj_fun(O_updated)

    for run_idx in range(MaxRuns):
        theta = thetaInitial

        print(f"=> Maxtime for the current session: {MaxTime:.2f}")
        print("=> Python BOOOM call started")

        if run_idx == 0:
            O_updated = O_initial.copy()

        for iter_idx in range(MaxIter):
            elapsed = time.time() - start_time
            if elapsed > MaxTime:
                break_now = True
                print(f"=> As requested, BOOOM has been terminated after {MaxTime:.2f} seconds :(")
                print()
                break

            O = O_updated.copy()
            InitialValue = obj_fun(O)

            # --------------------------------
            # Time-based progress display
            # --------------------------------
            now_elapsed = time.time() - start_time
            if DisplayUpdate == 1:
                if now_elapsed - last_print_time > DisplayEvery:
                    if PrintStepSize == 1:
                        print(
                            f"=> Executing Run: {run_idx + 1}, "
                            f"iter: {iter_idx + 1}, "
                            f"current obj. fun. value: {InitialValue:.10f}, "
                            f"current log10(step-size/pi): {math.log10(theta / math.pi):.2f}."
                        )
                    else:
                        print(
                            f"=> Executing Run: {run_idx + 1}, "
                            f"iter: {iter_idx + 1}, "
                            f"current obj. fun. value: {InitialValue:.10f}."
                        )
                    last_print_time = now_elapsed

            # --------------------------------
            # Evaluate all 2 * num_rotations moves
            # --------------------------------
            fun_vals_moves = np.zeros(total_moves, dtype=float)

            for idx in range(total_moves):
                change_loc = idx // 2             # 0-based version of ceil(idx/2) in MATLAB pattern
                sign = 1 if (idx % 2 == 0) else -1

                r_i, r_j = pairs[change_loc]
                O_rotated = create_premultiplied_matrix(O, r_i, r_j, sign * theta)
                value = obj_fun(O_rotated)
                fun_vals_moves[idx] = value

            minIndex = int(np.argmin(fun_vals_moves))
            minValue = float(fun_vals_moves[minIndex])

            CurrentValue = InitialValue

            if minValue < InitialValue:
                base_idx = minIndex // 2
                sign = 1 if (minIndex % 2 == 0) else -1
                theta_signed = sign * theta

                r_i, r_j = pairs[base_idx]
                O_updated = create_premultiplied_matrix(O, r_i, r_j, theta_signed)
                CurrentValue = obj_fun(O_updated)

            # --------------------------------
            # Step-size reduction rule
            # --------------------------------
            if iter_idx > 0:
                if abs(CurrentValue - InitialValue) < TolFun1:
                    if theta > phi:
                        theta = theta / rho
                    else:
                        break

        run_soln_array[run_idx] = CurrentValue

        # --------------------------------
        # Across-run stopping rule
        # --------------------------------
        if run_idx > 0:
            if abs(run_soln_array[run_idx] - run_soln_array[run_idx - 1]) < TolFun2:
                break

        if break_now:
            break

    O_opt = O_updated
    fval = obj_fun(O_opt)
    comp_time = time.time() - start_time

    if PrintSolution == 1:
        print()
        print("=> Final BOOOM solution is:")
        print(O_opt)

    print()
    print(f"=> Obj. fun. value at BOOOM minima: {fval:.10f}")
    print()
    print(f"=> Total time taken: {comp_time:.4f} secs.")
    print("xxxxxxxxxxxxxxxxxxxxxx BOOOM ends xxxxxxxxxxxxxxxxxxxxxxxxxx")

    return O_opt, fval, comp_time