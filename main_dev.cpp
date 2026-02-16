#include <voro++.hh>
#include <algorithm>
#include <iostream>
#include <set>
#include <vector>

int main() {
    using namespace voro;

    constexpr int N = 25;
    const double L = 8.0;

    // Same dataset as the "master" reproduction.
    const double pts[N][3] = {
        {0.68519333714899489, 1.8944840527687976, 6.4101957216511751},
        {4.6572962885149423, 0.75302913792319348, 3.4650155218917904},
        {3.8324103851266722, 1.2779113170966285, 5.8766172112737163},
        {0.90937615937122729, 3.1298255239652963, 4.1339214609709094},
        {3.4450241633134224, 4.6943885715051259, 5.9027022983372817},
        {7.6501380386887883, 2.2736093099903316, 5.1883776566386004},
        {5.5697279733612435, 2.341765992099897, 0.011920668070689366},
        {7.7876821981313018, 2.3872097841350053, 2.5118880162746944},
        {7.1336885635612575, 4.6813035191272645, 3.770477321454651},
        {6.1862160771905312, 0.24276806129976958, 5.6557207652449879},
        {2.9939506678277663, 0.72682170803406265, 5.2840005394231581},
        {7.451710837930836, 1.65752934464801, 5.0407215982827442},
        {2.385304725259398, 5.9340534405546434, 5.7773184651369397},
        {1.7497233965504364, 6.6390949941944982, 5.2612176869859457},
        {5.4623912628828019, 6.5606060013642797, 3.4285832343876956},
        {6.069643689239352, 7.0278414773300308, 0.81855937537659516},
        {6.79814669972923, 3.151418661058681, 3.8374713880981997},
        {1.1706765580655878, 5.5874107595767479, 2.335828927902808},
        {6.9691131983487129, 2.2029950155846167, 4.4944777498471194},
        {3.197249769043622, 4.9032759352195133, 1.5731139181769898},
        {1.4423003267447614, 5.9748830851987027, 6.0177873469542187},
        {4.5358229956232979, 7.3686374182634395, 1.6462003858321506},
        {6.8072089967332117, 1.3518984906166898, 7.7148617671542366},
        {4.989541824849214, 4.8550703040801178, 7.7644701050609902},
        {6.2962617103101679, 6.3193398087084347, 0.4327500629677221}
    };

    const double radii[N] = {
        0.24771452243776798, 0.13395790886618722, 0.17741103258620577,
        0.18554679627685888, 0.44345677286636176, 0.15070199188732217,
        0.2187031073557798, 0.29713879156973305, 0.43978416447581475,
        0.4860925683349502, 0.3832579082748967, 0.18547488777221927,
        0.31799307258320164, 0.3823836171947548, 0.12075301109065006,
        0.3719536668896286, 0.24731273405563245, 0.33588011471168333,
        0.36781331245666604, 0.36765099845837435, 0.30921991021034256,
        0.3218949729860357, 0.1792598854454132, 0.2980749566141609,
        0.15016378905810127
    };

    // Dev branch uses explicit "_3d" class names.
    container_poly_3d con(0.0, L, 0.0, L, 0.0, L,
                          1, 1, 1,
                          true, true, true,
                          8);

    for (int i = 0; i < N; ++i) {
        con.put(i, pts[i][0], pts[i][1], pts[i][2], radii[i]);
    }

    // Sum of cell volumes should equal L^3 for a correct tessellation in a periodic box.
    double vol_sum = 0.0;
    {
        voronoicell_neighbor_3d cell;
        for (container_poly_3d::iterator it = con.begin(); it != con.end(); ++it) {
            if (con.compute_cell(cell, it)) {
                vol_sum += cell.volume();
            }
        }
    }
    std::cout << "Total volume sum: " << vol_sum << " (expected " << (L * L * L) << ")\n";

    // Print detailed info for pid 0 and pid 9.
    std::set<int> neigh0, neigh9;
    for (int target : {0, 9}) {
        voronoicell_neighbor_3d cell;
        bool found = false;

        for (container_poly_3d::iterator it = con.begin(); it != con.end(); ++it) {
            int pid = con.pid(it);
            if (pid != target) continue;

            double x, y, z;
            con.pos(it, x, y, z);

            if (!con.compute_cell(cell, it)) {
                std::cerr << "compute_cell failed for pid=" << pid << "\n";
                return 2;
            }

            std::vector<int> neigh;
            cell.neighbors(neigh);

            std::vector<int> fverts;
            cell.face_vertices(fverts);

            std::vector<double> verts;
            cell.vertices(x, y, z, verts);

            std::cout << "\nPID " << pid << "\n";
            std::cout << "  volume: " << cell.volume() << "\n";
            std::cout << "  number_of_faces(): " << cell.number_of_faces()
                      << "  neighbors.size(): " << neigh.size()
                      << "  face_vertices.size(): " << fverts.size() << "\n";
            std::cout << "  vertex_count: " << (verts.size() / 3) << "\n";

            std::set<int> nset(neigh.begin(), neigh.end());
            std::cout << "  unique neighbor IDs: ";
            for (int n : nset) std::cout << n << " ";
            std::cout << "\n";

            if (pid == 0) neigh0 = std::move(nset);
            if (pid == 9) neigh9 = std::move(nset);

            found = true;
            break;
        }

        if (!found) {
            std::cerr << "Could not find pid=" << target << " in iterator\n";
            return 3;
        }
    }

    const bool zero_has_9 = (neigh0.find(9) != neigh0.end());
    const bool nine_has_0 = (neigh9.find(0) != neigh9.end());

    std::cout << "\nReciprocity check:\n";
    std::cout << "  pid 0 has neighbor 9: " << (zero_has_9 ? "YES" : "NO") << "\n";
    std::cout << "  pid 9 has neighbor 0: " << (nine_has_0 ? "YES" : "NO") << "\n";

    return 0;
}
