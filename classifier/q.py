import pickle
import re
import math
import os
import statistics
import numpy as np
import glob
from sklearn.cluster import AgglomerativeClustering


class Rectangle:
    def __init__(self, id, x, y, w, h):
        self.id = id
        self.x = x
        self.y = y
        self.w = w
        self.h = h

    def contains(self, otherrect):
        if self.x <= otherrect.x <= self.x + self.w and \
                self.y <= otherrect.y <= self.y + self.h and \
                self.x <= otherrect.x + otherrect.w <= self.x + self.w and \
                self.y <= otherrect.y + otherrect.h <= self.y + self.h:
            return True
        return False

    def split(self, max_width, max_height):
        rects = self.split_horz(max_width)
        rects_ret = []
        for r in rects:
            rects_ret.extend(r.split_vert(max_height))
        return rects_ret

    def split_horz(self, max_width):
        n_outputs = int(math.ceil(float(self.w)/float(max_width)))
        split_width = self.w / n_outputs
        rects = []
        for i in range(n_outputs):
            new_id = "{}_{}".format(self.id, i)
            r = Rectangle(new_id, self.x + i * split_width, self.y, split_width, self.h)
            rects.append(r)
        return rects

    def split_vert(self, max_height):
        n_outputs = int(math.ceil(float(self.h)/float(max_height)))
        split_height = self.h / n_outputs
        rects = []
        for i in range(n_outputs):
            new_id = "{}_{}".format(self.id, i)
            r = Rectangle(new_id, self.x, self.y + i * split_height, self.w, split_height)
            rects.append(r)
        return rects

    def join(self, otherrect):
        x = min(self.x, otherrect.x)
        y = min(self.y, otherrect.y)
        x_max = max(self.x+self.w, otherrect.x+otherrect.w)
        y_max = max(self.y+self.h, otherrect.y+otherrect.h)
        return Rectangle(self.id, x, y, x_max-x, y_max-y)

    def overlaps(self, otherrect):
        if (self.x <= otherrect.x <= self.x + self.w or \
                self.x <= otherrect.x + otherrect.w <= self.x + self.w) and \
                (self.y - 1 <= otherrect.y <= self.y + self.h + 1 or \
                self.y - 1 <= otherrect.y + otherrect.h <= self.y + self.h + 1):
            return True
        return False

    def magick_crop(self):
        return "-crop {}x{}+{}+{}".format(self.w, self.h, self.x, self.y)

    def magick_draw(self):
        return "-draw \"rectangle {},{} {},{}\"".format(self.x, self.y, self.x+self.w, self.y+self.h)


def load_and_correct_rectangles(f, f_txt, split_ratio=1.5, min_width=5, min_height=8):
    rects = load_raw_rects(f_txt)
    rects = remove_subrects(rects)
    rects = remove_headerrects(rects)
    rects = join_overlaps(rects)
    rects = split_rects(rects, split_ratio)
    rects = filter_tiny_rects(rects, min_width, min_height)

    return rects


# 5x7, 7x10
def filter_tiny_rects(rects, min_width, min_height):
    return [r for r in rects if r.w > min_width and r.h > min_height]


def remove_headerrects(rects):
    if rects is None or 0 == len(rects):
        return rects
    y_cutoff = sorted([r.y for r in rects])[15] + (2 * rects[0].h)
    # y_cutoff = min([r.y for r in rects]) + (2 * rects[0].h)
    return [r for r in rects if r.y > y_cutoff]


def join_overlaps(rects):
    rects_ret = []
    rects_removed = []
    for r1 in rects:
        for r2 in rects:
            if r1 == r2 or r1 in rects_removed or r2 in rects_removed:
                continue
            if r1.overlaps(r2):
                rects_ret.append(r1.join(r2))
                rects_removed.append(r1)
                rects_removed.append(r2)
    new_rects = [r for r in rects if r not in rects_removed]
    rects_ret.extend(new_rects)

    if len(rects) == len(rects_ret):
        return rects_ret
    return join_overlaps(rects_ret)


# Ratios between 1 and 2 at 1.2, 1.5, 1.8
def split_rects(rects, split_ratio):
    if rects is None or 0 == len(rects):
        return []
    w = statistics.median([r.w for r in rects]) * split_ratio
    h = statistics.median([r.h for r in rects]) * split_ratio
    rects_ret = []
    for r in rects:
        rects_ret.extend(r.split(w, h))
    return rects_ret


def remove_subrects(rects):
    remove_contained = []
    if rects is None:
        return rects
    for r1 in rects:
        for r2 in rects:
            if r1 != r2 and r1.contains(r2):
                remove_contained.append(r2)
    rects_unsplit = [r for r in rects if r not in remove_contained]
    return rects_unsplit


def load_raw_rects(f_txt):
    original_rects = []
    with open(f_txt, "r") as fh:
        for l in fh.readlines():
            m = re.search("(?P<id>\\d+):\\s*(?P<w>\\d+)x(?P<h>\\d+)\+(?P<x>\\d+)\+(?P<y>\\d+)", l)
            if m is None or (int(m.group("h")) > 50):
                # Skip the "whole page" one
                continue
            rect = Rectangle(int(m.group("id")), int(m.group("x")), int(m.group("y")),
                             int(m.group("w")), int(m.group("h")))
            original_rects.append(rect)
    return original_rects


def load_digits(f_csv):
    digirs = {}
    with open(f_csv, "r") as fh:
        for l in fh.readlines():
            digit_num, digit = l.split(",")
            digirs[int(digit_num)] = int(digit)
    return digirs


def draw_rects(rects, in_png, out_png):
    convertstr = "convert " + in_png + " -fill none -stroke red -strokewidth 0.5 " + \
                 " ".join([r.magick_draw() for r in rects]) + " " + out_png
    os.system(convertstr)


def extract_rect(rect, in_png, out_png):
    convertstr = "convert " + in_png + " " + rect.magick_crop() + " -gravity center -extent 17x22 " + out_png
    os.system(convertstr)


# "page" like "n'th sheet of paper", not "page" like "number in top of page"
row_zero_on_page = 5
rows_per_page = 50
digits_per_row = 50
row_number_width = 5
digits_per_page = digits_per_row * rows_per_page


def digit_num_to_page_x_y(digitnum_1offset):
    digitnum = digitnum_1offset-1
    digt_pg = digitnum/digits_per_page
    page_offset = math.floor(digt_pg)
    n_into_page = digitnum % digits_per_page
    rownum = math.floor(n_into_page/digits_per_row)
    col = n_into_page % digits_per_row
    return page_offset + row_zero_on_page, col+row_number_width, rownum


def page_to_digit_range(page):
    low = math.floor((page-row_zero_on_page)*digits_per_page)
    return low+1, low+digits_per_page


# 350212	7004	2	1	8	8
print(digit_num_to_page_x_y(352500))
print(page_to_digit_range(145))
print(page_to_digit_range(146))

step2_dir = "../ocr/step2/"
step3_dir = "../ocr/step3/"
digit_dir = "../ocr/digits/"

for d in range(10):
    if not os.path.exists(digit_dir + str(d)):
        os.mkdir(digit_dir + str(d))

# first_digit = 1
# last_digit = 1000000
first_digit = 350001
last_digit = 400000
min_page = digit_num_to_page_x_y(first_digit)[0]
max_page = digit_num_to_page_x_y(last_digit)[0]

digits_by_id = load_digits("id_digit.csv")

# imgs = sorted(glob.glob(step2_dir + "*.png"))
# for img in imgs:
#    basename = os.path.basename(img)
for page in range(min_page, max_page+1):
    basename = 'src-{:03d}.png'.format(page)
    img = step2_dir + basename
    in_interest_area = False
    if 'src-145.png' <= basename <= 'src-164.png':
        in_interest_area = True

    file_txt = os.path.join(step3_dir, basename) + ".txt"
    rects_pickle = os.path.join(step3_dir, basename) + ".pkl"
    rects = []
    if os.path.exists(rects_pickle):
        with open(rects_pickle, "rb") as pkl_f:
            rects = pickle.load(pkl_f)
    else:
        rects = load_and_correct_rectangles(img, file_txt, split_ratio=1.5, min_width=5, min_height=8)

    rects_np = np.array(rects)
    ys = [[r.y, 0] for r in rects]

    if rows_per_page >= len(rects):
        # Sanity check that we're at least looking at a page of digits
        continue

    clustering = AgglomerativeClustering(n_clusters=rows_per_page).fit(ys)

    clusters_sorted = []
    for cluster in range(rows_per_page):
        this_cluster = (clustering.labels_ == cluster)
        these_rects = rects_np[clustering.labels_ == cluster]
        these_rects = sorted(these_rects, key=lambda r: r.x)
        clusters_sorted.append(these_rects)
    clusters_sorted.sort(key=lambda c: c[0].y)

    non_correct_len_rows = [n for n in range(len(clusters_sorted)) if 55 != len(clusters_sorted[n])]

    think_its_good = (len(rects) == 2750 and 0 == len(non_correct_len_rows))

    print("{} : {} rects {}".format(basename, len(rects), "" if think_its_good else "!"))

    if len(non_correct_len_rows) > 0:
        print("Problems in rows " + ", ".join([str(n) for n in non_correct_len_rows]))

    if think_its_good:
        with open(rects_pickle, "wb") as pkl_f:
            pickle.dump(rects, pkl_f)

        low_digit, high_digit = page_to_digit_range(page)
        for digit_num in range(low_digit, high_digit+1):
            p_x_y = digit_num_to_page_x_y(digit_num)
            this_digit = digits_by_id[digit_num]
            if True or this_digit == 0 or this_digit == 2:
                out_file = digit_dir + str(this_digit) + "/" + str(digit_num) + ".png"
                row = clusters_sorted[p_x_y[2]]
                rect = row[p_x_y[1]]
                extract_rect(rect, img, out_file)
                if digit_num == 352500:
                    draw_rects([rect], img, "rect_352500.png")

    draw_rects(rects, img, os.path.join(step3_dir, "rect_" + basename))
