#!/usr/bin/env bash

wdr=${1:-/data}

### Main ###

cwd=$( pwd )

cd ${wdr}/CVR

for sub in 001 002 003 004 007 008 009
do
	for ses in $( seq -f %02g 1 10 )
	do
		for ftype in optcom echo-2 meica-aggr meica-orth meica-preg meica-mvar meica-recn vessels-preg
		do
			case "${ftype}" in
				meica* | vessels* | networks* ) tscore=3.367	;;
				optcom | echo-2 ) tscore=1.968 ;;
				* ) echo "There's a major screw-up here"; exit ;;
			esac

			echo "sub ${sub} ses ${ses} ftype ${ftype}"
			echo "cvr"
			fsleyes render -of ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr --size 1400 500 --scene lightbox --sliceSpacing 18 --zrange 21 131 \
			--ncols 6 --nrows 1 --hideCursor --bgColour 0.0 0.0 0.0 --fgColour 1.0 1.0 1.0 --showColourBar --colourBarLocation top \
			--colourBarLabelSide top-left --colourBarSize 50 --labelSize 11 \
			--performance 3 ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr.nii.gz \
			--name "cvr original" --overlayType volume --alpha 100.0 --cmap red-yellow --negativeCmap blue-lightblue --useNegativeCmap \
			--displayRange 0.0 0.6 --clippingRange 0.0 10.0 --gamma 0.0 --cmapResolution 256 --interpolation none --numSteps 100 --blendFactor 0.1 \
			--smoothing 0 --resolution 100 --numInnerSteps 10 --clipMode intersection --volume 0
			fsleyes render -of ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_masked --size 1400 500 --scene lightbox --sliceSpacing 18 --zrange 21 131 \
			--ncols 6 --nrows 1 --hideCursor --bgColour 0.0 0.0 0.0 --fgColour 1.0 1.0 1.0 --showColourBar --colourBarLocation top \
			--colourBarLabelSide top-left --colourBarSize 50 --labelSize 11 \
			--performance 3 ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_masked.nii.gz \
			--name "cvr masked" --overlayType volume --alpha 100.0 --cmap red-yellow --negativeCmap blue-lightblue --useNegativeCmap \
			--displayRange 0.0 0.6 --clippingRange 0.0 10.0 --gamma 0.0 --cmapResolution 256 --interpolation none --numSteps 100 --blendFactor 0.1 \
			--smoothing 0 --resolution 100 --numInnerSteps 10 --clipMode intersection --volume 0
			fsleyes render -of ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_corrected --size 1400 500 --scene lightbox --sliceSpacing 18 --zrange 21 131 \
			--ncols 6 --nrows 1 --hideCursor --bgColour 0.0 0.0 0.0 --fgColour 1.0 1.0 1.0 --showColourBar --colourBarLocation top \
			--colourBarLabelSide top-left --colourBarSize 50 --labelSize 11 \
			--performance 3 ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_corrected.nii.gz \
			--name "cvr corrected" --overlayType volume --alpha 100.0 --cmap red-yellow --negativeCmap blue-lightblue --useNegativeCmap \
			--displayRange 0.0 0.6 --clippingRange 0.0 10.0 --gamma 0.0 --cmapResolution 256 --interpolation none --numSteps 100 --blendFactor 0.1 \
			--smoothing 0 --resolution 100 --numInnerSteps 10 --clipMode intersection --volume 0
			fsleyes render -of ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_tmap --size 1400 500 --scene lightbox --sliceSpacing 18 --zrange 21 131 \
			--ncols 6 --nrows 1 --hideCursor --bgColour 0.0 0.0 0.0 --fgColour 1.0 1.0 1.0 --showColourBar --colourBarLocation top \
			--colourBarLabelSide top-left --colourBarSize 50 --labelSize 11 \
			--performance 3 ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_tmap.nii.gz \
			--name "tmap" --overlayType volume --alpha 100.0 --cmap red-yellow --negativeCmap blue-lightblue --useNegativeCmap \
			--displayRange ${tscore} 50.0 --clippingRange ${tscore} 100.0 --gamma 0.0 --cmapResolution 256 --interpolation none --numSteps 100 --blendFactor 0.1 \
			--smoothing 0 --resolution 100 --numInnerSteps 10 --clipMode intersection --volume 0
			echo "lag"
			fsleyes render -of ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_lag --size 1400 500 --scene lightbox --sliceSpacing 18 --zrange 21 131 \
			--ncols 6 --nrows 1 --hideCursor --bgColour 0.0 0.0 0.0 --fgColour 1.0 1.0 1.0 --showColourBar --colourBarLocation top \
			--colourBarLabelSide top-left --colourBarSize 50 --labelSize 11 \
			--performance 3 ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_lag.nii.gz \
			--name "cvr lag original" --overlayType volume --alpha 100.0 --cmap brain_colours_actc_iso --invert \
			--displayRange -9 9 --clippingRange -9 9 --gamma 0.0 --cmapResolution 256 --interpolation none --numSteps 100 --blendFactor 0.1 \
			--smoothing 0 --resolution 100 --numInnerSteps 10 --clipMode intersection --volume 0
			fsleyes render -of ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_lag_corrected --size 1400 500 --scene lightbox --sliceSpacing 18 --zrange 21 131 \
			--ncols 6 --nrows 1 --hideCursor --bgColour 0.0 0.0 0.0 --fgColour 1.0 1.0 1.0 --showColourBar --colourBarLocation top \
			--colourBarLabelSide top-left --colourBarSize 50 --labelSize 11 \
			--performance 3 ${wdr}/CVR/sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_lag_corrected.nii.gz \
			--name "cvr lag corrected" --overlayType volume --alpha 100.0 --cmap brain_colours_actc_iso --invert \
			--displayRange -9 9 --clippingRange -9 9 --gamma 0.0 --cmapResolution 256 --interpolation none --numSteps 100 --blendFactor 0.1 \
			--smoothing 0 --resolution 100 --numInnerSteps 10 --clipMode intersection --volume 0
			montage -append sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr.png \
			sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_masked.png \
			sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_corrected.png \
			tmp.${sub}_${ses}_${ftype}_1.png
			montage -append sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_lag.png \
			sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_tmap.png \
			sub-${sub}_ses-${ses}_${ftype}_map_cvr/sub-${sub}_ses-${ses}_${ftype}_cvr_lag_corrected.png \
			tmp.${sub}_${ses}_${ftype}_2.png
			montage -background black +append tmp.${sub}_${ses}_${ftype}_1.png tmp.${sub}_${ses}_${ftype}_2.png sub-${sub}_ses-${ses}_${ftype}.png
			rm tmp.${sub}_${ses}_${ftype}_?.png
		done
	done

	# Creating full sessions maps
	appending="montage -append"
	for ftype in echo-2 optcom meica-aggr meica-orth meica-preg meica-mvar meica-recn vessels-preg
	do
		for ses in $( seq -f %02g 1 9 )
		do
			echo "sub ${sub} ses ${ses} ftype ${ftype}"
			montage sub-${sub}_ses-${ses}_${ftype}.png -crop 234x265+466+642 tmp.${sub}_${ses}_${ftype}.png
		done
		montage +append tmp.${sub}_??_${ftype}.png +repage tmp.${sub}_${ftype}.png
		appending="${appending} tmp.${sub}_${ftype}.png"
	done
	appending="${appending} sub-${sub}_alltypes.png"
	exec "${appending}"
done

cd ${cwd}
