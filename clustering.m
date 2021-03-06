function [xyzCleaned, rgbCleaned, clusters, cluster2mean, clusterIds, cubeId] = clustering(xyz, rgb)
  %{
  #Description
  using Density based clustering. The code for clustering is by
  % Michal Daszykowski
  % Department of Chemometrics, Institute of Chemistry, 
  % The University of Silesia
  % December 2004
  % http://www.chemometria.us.edu.pl

  Works in two phases. First initial/raw clustering is done. After that
  the biggest cluster is located which must belong to cube. Next, the
  remaining clusters are checked by proximity to the cube cluster. If they
  are too far way then they are recognised as border outliers and removed.
  If outliers were detected then after their removal additional clustering
  is used to get final results. 
  Regions of small connectivity are marked by -1 id.

  #Input
  * xyz - coordinates of cloud points. Size: number of points x 3
  * rgb - colors of cloud points. Size: number of points x 3

  #Output
  * xyzCleaned - coordinates cleaned values from border outliers 
  * rgbCleaned - colors cleaned values from border outliers 
  * clusters - vector of xyzCleaned/rgbCleaned correspondence to the cluster Ids
  * cluster2mean - dictionary which keeps cluster mean points
  * clusterIds - cluster Ids vector including -1 index (regions of small 
    connectivity)
  * cubeId - id of the biggest cluster. It must correspond to cube
  %}

  %subroutine to have ability to repeat clustering several times if it is
  %necessary
  function [clusters_, cluster2mean_, clusterIds_, cubeId_] = subclustering(xyz_, nMinPoints, eps)
    if nargin == 3
      [clusters_, type]=dbscan(xyz_, nMinPoints, eps);
    else
      [clusters_, type]=dbscan(xyz_, nMinPoints);
    end
    %[clusters_, type]=dbscan(xyz_, 100);
    %class_ -> 1 x number of points
    clusterIds_ = unique(clusters_);
    cluster2mean_ = containers.Map('KeyType','double','ValueType','any');
    cubeId_ = -1;
    
    %find biggest cluster
    %it must be cube
    biggestArea = -1;
    for j = 1:length(clusterIds_)
      clusterId_ = clusterIds_(j);
      xyzCluster = xyz_(clusters_ == clusterId_, :);
      cluster2mean_(clusterId_) = mean(xyzCluster);
      area = size(xyzCluster, 1);
      if area > biggestArea
        cubeId_ = clusterId_;
        biggestArea = area;
      end
    end    
  end
  
  %inital clustering
  %parameters: minimal number of points in cluster and radius of 
  %connectivity to closest neighbours. Exact values are found imperically.
  [clusters, cluster2mean, clusterIds, cubeId] = subclustering(xyz, 80, 0.015);
  
  %check for border outliers -> points which are too far away from the cube 
  cubeMean = cluster2mean(cubeId);
  outlierThreshold = 0.4;
  outliersIds = zeros(1, length(clusters));
  hasOutliers = 0;
  
  for i = 1:length(clusterIds)
    clusterId = clusterIds(i);
    clusterMean = cluster2mean(clusterId);
    dist = norm(clusterMean - cubeMean);
    if dist > outlierThreshold
      hasOutliers = 1;
      outliersIds = outliersIds | (clusters == clusterId);
    end
  end
  
  
  if hasOutliers == 1
    %border outliers are present
    %clean the data
    fprintf('border outliers are detected. Cleaning and reclustering');
    cleanedIds = ~(outliersIds);
    xyzCleaned = xyz(cleanedIds, :);
    rgbCleaned = rgb(cleanedIds, :);
    %once border outliers are removed, do final clustering
    [clusters, cluster2mean, clusterIds, cubeId] = subclustering(xyzCleaned, 80, 0.015);
  else
    xyzCleaned = xyz;
    rgbCleaned = rgb;
  end

end

