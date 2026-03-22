
function O_updated = create_premultiplied_matrix(O, r_i, r_j, theta)
    % Create pre multiplied Ortogonal matrix  

    term_1 = O(r_i,:)*cos(theta);
    term_2 = O(r_i,:)*sin(theta);

    term_3 = O(r_j,:)*cos(theta);
    term_4 = O(r_j,:)*sin(theta);

    O_updated = O;

    O_updated([r_i,r_j],:) = [term_1 - term_4; term_2 + term_3];
    
end
