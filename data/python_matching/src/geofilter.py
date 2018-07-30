#!/usr/bin/env python
import argparse
import pandas as pd
import numpy as np
from numba import jit, boolean
from scipy.linalg import norm


def levenshteinDistance(s1, s2):
    """Finds the Levenshtein Distance between tww strings using lists from the
       standard python library.

    Parameters: two strings(s1, s2)
    Returns: integer representing edit distance
             e.g. levenshteinDistance("What", "When") returns 2
    """
    if len(s1) > len(s2):
        s1, s2 = s2, s1
    distances = range(len(s1) + 1)
    for i2, c2 in enumerate(s2):
        distances_ = [i2+1]
        for i1, c1 in enumerate(s1):
            if c1 == c2:
                distances_.append(distances[i1])
            else:
                distances_.append(1 + min((distances[i1], distances[i1 + 1], distances_[-1])))
        distances = distances_
    return distances[-1]


def editDistance(s, t):
    """Finds the Edit Distance between two strings using Numpy arrays.

    Parameters: two strings(s, t)
    Returns: float representing edit distance
             e.g. editDistance("What", "When") returns 2.0
    """
    i = np.arange(len(s) + 1)
    j = np.arange(len(t) + 1)
    dist = np.zeros((len(i),len(j)))
    dist[0] = j
    dist[:,0] = i
    for col in range(0, len(i)-1):
        for row in range(0, len(j)-1):
            if s[row-1] == t[col-1]:
                cost = 0
            else:
                cost = 1
            dist[row][col] = min(dist[row-1][col] + 1,
                                 dist[row][col-1] + 1,
                                 dist[row-1][col-1] + cost)
            ans = dist[row][col]
    return ans


def filterRadius(df, r):
    """ Finds matching stores based on the stores' latitude and longitude by
        checking to see if:
        1. if two stores are within a radius, r, of each other
        2. if the storeids are equal
        3. and editdistance between the store names is less than 4

    Parameters: (df) a Pandas DataFrame that hold information on store_name, latitude,
                longitude, and a store id
                (r) the search radius
    Returns:    (d) a Pandas DataFrame that holds all the matches
                    - contains both store names, the address edit distance, append
                      the edit distance between the names
    """
    d = pd.DataFrame()
    for i in range(0, len(df)):
        for j in range(0, len(df)):
            a = np.array([[abs(df['long'][i]), df['lat'][i]]])
            b = np.array([[abs(df['long'][j]), df['lat'][j]]])
            if norm(a - b) < r and df['storeid'][i] != df['storeid'][j] and (levenshteinDistance(str(df['store_name'][i]), str(df['store_name'][j])) < 6):
                    d2 = pd.DataFrame([[df['store_name'][i],
                                        df['store_name'][j],
                                        levenshteinDistance(str(df['address'][i]),
                                                            str(df['address'][j])),
                                        levenshteinDistance(str(df['store_name'][i]),
                                                            str(df['store_name'][j]))]],
                                                            columns=['store1', 'store2', 'address_distence', 'name_distance'])
                    d = pd.concat([d, d2], ignore_index=True)
                    d = pd.concat([d, d2], ignore_index=True)
    return d

@jit
def filterWidth(df, r, w):
    """ Finds matches in a SORTED DataFrame by checking a range of rows, w, in
        the DataFrame, df, to see if any matches exist with in a radius, r, of
        the stores' longitudes and latitudes.

        Using rangeWidth(df, r, w) instead of filterRadius(df, r) is considerably
        faster and generates less false positives if df is sorted.

    Parameters: (df) a Pandas DataFrame that hold information on store_name, latitude,
                longitude, and a store id
                (r) the search radius
                (w) the range of rows checked for matches at one time
    Returns:    (d) a Pandas DataFrame that holds all the matches
                    - contains both store names, the address edit distance, append
                      the edit distance between the names
    """
    d = pd.DataFrame()
    beg = 0
    end = w
    while(end <= len(df)):
        for i in range(beg, end):
            for j in range(i+1, end):
                a = np.array([[abs(df['long'][i]), df['lat'][i]]])
                b = np.array([[abs(df['long'][j]), df['lat'][j]]])
                if norm(a - b) < r and df['storeid'][i] != df['storeid'][j] and (levenshteinDistance(str(df['store_name'][i]), str(df['store_name'][j])) < 6):
                        d2 = pd.DataFrame([[df['store_name'][i],
                                            df['storeid'][i],
                                            df['store_name'][j],
                                            df['storeid'][j],
                                            levenshteinDistance(str(df['address'][i]),
                                                                str(df['address'][j])),
                                            levenshteinDistance(str(df['store_name'][i]),
                                                                str(df['store_name'][j]))]],
                                                                columns=['store1id', 'store1name' ,'store2name', 'store2name','address_distence', 'name_distance'])
                        d = pd.concat([d, d2], ignore_index=True)
        beg = end
        end = end + w
    for i in range(end, len(df)):
        for j in range(end, len(df)):
            a = np.array([[abs(df['long'][i]), df['lat'][i]]])
            b = np.array([[abs(df['long'][j]), df['lat'][j]]])
            if norm(a - b) < r and df['storeid'][i] != df['storeid'][j] and (levenshteinDistance(str(df['store_name'][i]), str(df['store_name'][j])) < 6):
                d2 = pd.DataFrame([[df['store_name'][i],
                                    df['storeid'][i],
                                    df['store_name'][j],
                                    df['storeid'][j],
                                    levenshteinDistance(str(df['address'][i]),
                                                        str(df['address'][j])),
                                    levenshteinDistance(str(df['store_name'][i]),
                                                        str(df['store_name'][j]))]],
                                                        columns=['store1id', 'store1name' ,'store2name', 'store2name','address_distence', 'name_distance'])
                d = pd.concat([d, d2], ignore_index=True)
    return d


if __name__ == "__main__":
    # creates commnand line argument '-r' and '--radius'
    parser = argparse.ArgumentParser()
    parser.add_argument("-r", "--radius", action='store', dest='r', default=0.005, type=float,
        help = "Sets the search radius.")
    # creates command line argument '-i' and '--input'
    parser.add_argument("-i", "--input", required = True, action='store', dest='i', type=str,
        help = "Path to the input CSV file.")
    # crates command line argument '-w' and '--width'
    parser.add_argument("-w", "--width", action = 'store', dest='w', default = 50, type=int,
        help = "Sets the width of the search.")
    args = parser.parse_args()
    #reads csv
    df1 = pd.read_csv(args.i, encoding = "latin1", low_memory = False)

    address_matches = filterWidth(df1, args.r, args.w)

    address_matches.to_csv('snap_matches_from_rangeFilter.csv')
