function ea_hyperlink_label(label, url, position)
labelStr = ['<html><a href="">' label '</a></html>'];
jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
[hjLabel,~] = javacomponent(jLabel, position, gcf);
bgcolor = num2cell(get(gcf, 'Color'));
hjLabel.setBackground(java.awt.Color(bgcolor{:}));
hjLabel.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));
hjLabel.setToolTipText(['Click to visit ' url]);
set(hjLabel, 'MouseClickedCallback', @(h,e)web(url, '-browser'))
